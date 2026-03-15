import { execSync } from "child_process";
import { readdirSync, readFileSync, writeFileSync, mkdirSync, rmSync, existsSync } from "fs";
import { join, basename } from "path";

const GREEN = "\x1b[1;32m";
const RED = "\x1b[1;31m";
const NC = "\x1b[0m";

const success = (msg: string): void => console.log(`${GREEN}${msg}${NC}`);
const error = (msg: string): void => console.error(`${RED}${msg}${NC}`);

const printDiff = (snapshotPath: string, actual: string): void => {
  const tmpPath = `${snapshotPath}.tmp`;
  writeFileSync(tmpPath, actual);
  try {
    execSync(`diff --color=always -u ${snapshotPath} ${tmpPath}`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
  } catch (e: unknown) {
    const err = e as { stdout?: string };
    if (err.stdout) console.error(err.stdout);
  } finally {
    rmSync(tmpPath);
  }
};

type Snapshot = {
  name: string;
  content: string;
};

const splitHelmOutput = (output: string): Snapshot[] => {
  const grouped = new Map<string, string[]>();
  const order: string[] = [];
  const parts = output.split(/^---\s*$/m);

  for (const part of parts) {
    const trimmed = part.trim();
    if (!trimmed) continue;

    const sourceMatch = trimmed.match(/^# Source:\s*(.+)$/m);
    if (!sourceMatch) continue;

    const sourcePath = sourceMatch[1].trim();
    const fileName = sourcePath.replace(/\//g, "_");

    if (!grouped.has(fileName)) {
      grouped.set(fileName, []);
      order.push(fileName);
    }
    grouped.get(fileName)!.push(`---\n${trimmed}`);
  }

  return order.map((name) => ({
    name,
    content: `${grouped.get(name)!.join("\n")}\n`,
  }));
};

const getCaseName = (fileName: string): string =>
  basename(fileName).replace(/\.values\.yaml$/, "");

const getTestCases = (): string[] =>
  readdirSync(join(__dirname, "test-cases"))
    .filter((f) => f.endsWith(".yaml"))
    .sort();

const normalizeOutput = (output: string): string =>
  output.replace(/forcePodRestart:\s*"[^"]*"/g, 'forcePodRestart: "STABLE"');

const renderTemplate = (testCaseFile: string): string => {
  const chartDir = join(__dirname, "..");
  const defaultValues = join(__dirname, "default.values.yaml");
  const testCaseValues = join(__dirname, "test-cases", testCaseFile);

  const raw = execSync(
    `helm template agent ${chartDir} --namespace sanity-tests --kube-version 1.31.0 -f ${defaultValues} -f ${testCaseValues}`,
    { encoding: "utf-8" }
  );

  return normalizeOutput(raw);
};

const updateSnapshots = (): void => {
  const testCases = getTestCases();
  const snapshotsDir = join(__dirname, "snapshots");

  if (existsSync(snapshotsDir)) {
    rmSync(snapshotsDir, { recursive: true });
  }

  for (const testCaseFile of testCases) {
    const caseName = getCaseName(testCaseFile);
    const caseDir = join(snapshotsDir, caseName);
    mkdirSync(caseDir, { recursive: true });

    console.log(`Rendering: ${testCaseFile}`);
    const output = renderTemplate(testCaseFile);
    const documents = splitHelmOutput(output);

    for (const doc of documents) {
      writeFileSync(join(caseDir, doc.name), doc.content);
    }

    success(`  Created ${documents.length} snapshots for ${caseName}`);
  }

  success(`\nSnapshots updated successfully!`);
};

const validate = (): void => {
  const testCases = getTestCases();
  const snapshotsDir = join(__dirname, "snapshots");
  const failedCases: string[] = [];

  for (const testCaseFile of testCases) {
    const caseName = getCaseName(testCaseFile);
    const caseDir = join(snapshotsDir, caseName);

    if (!existsSync(caseDir)) {
      error(`Missing snapshot directory: snapshots/${caseName}/`);
      failedCases.push(caseName);
      continue;
    }

    const output = renderTemplate(testCaseFile);
    const rendered = splitHelmOutput(output);
    const renderedNames = new Set(rendered.map((d) => d.name));
    const existingFiles = new Set(
      readdirSync(caseDir).filter((f) => f.endsWith(".yaml"))
    );

    let caseFailed = false;

    for (const doc of rendered) {
      const snapshotPath = join(caseDir, doc.name);
      if (!existsSync(snapshotPath)) {
        error(`  [${caseName}] New template not in snapshot: ${doc.name}`);
        caseFailed = true;
        continue;
      }

      const existing = readFileSync(snapshotPath, "utf-8");
      if (existing !== doc.content) {
        error(`  [${caseName}] Diff in: ${doc.name}`);
        printDiff(snapshotPath, doc.content);
        caseFailed = true;
      }
    }

    for (const file of existingFiles) {
      if (!renderedNames.has(file)) {
        error(`  [${caseName}] Extra snapshot file no longer rendered: ${file}`);
        caseFailed = true;
      }
    }

    if (caseFailed) {
      failedCases.push(caseName);
    } else {
      success(`  [${caseName}] OK`);
    }
  }

  if (failedCases.length > 0) {
    error(`\nValidation failed for: ${failedCases.join(", ")}`);
    error("Run 'npm run sanity update-snapshots' to update snapshots.");
    process.exit(1);
  }

  success(`\nAll snapshots validated successfully!`);
};

const command = process.argv[2];

if (command === "update-snapshots") {
  updateSnapshots();
} else if (command === "validate") {
  validate();
} else {
  console.error(`Usage: npm run sanity <update-snapshots|validate>`);
  process.exit(1);
}
