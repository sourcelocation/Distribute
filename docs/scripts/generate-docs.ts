import { generateFiles } from 'fumadocs-openapi';
import { openapi } from '@/lib/openapi';
import fs from 'node:fs';
import path from 'node:path';

const FALLBACK_SWAGGER_URL =
  process.env.SWAGGER_URL ||
  'https://raw.githubusercontent.com/ProjectDistribute/distributor/refs/heads/master/docs/swagger.json';

const repoRoot = path.resolve(__dirname, '..', '..');
const localSwaggerPath = path.join(repoRoot, 'api', 'docs', 'swagger.json');

async function main() {
  const sourceLabel = fs.existsSync(localSwaggerPath) ? localSwaggerPath : FALLBACK_SWAGGER_URL;
  console.log('Fetching Swagger from:', sourceLabel);
  console.log('Is using GITHUB_TOKEN:', process.env.GITHUB_TOKEN ? 'yes' : 'no');

  let swaggerData: unknown;

  if (!process.env.SWAGGER_URL && fs.existsSync(localSwaggerPath)) {
    swaggerData = JSON.parse(fs.readFileSync(localSwaggerPath, 'utf-8'));
  } else {
    const response = await fetch(FALLBACK_SWAGGER_URL, {
      headers: {
        Authorization: `token ${process.env.GITHUB_TOKEN}`,
      },
    });
    if (!response.ok) throw new Error(`Failed to fetch swagger: ${response.statusText}`);
    swaggerData = await response.json();
  }

  const outputDir = path.resolve(__dirname, '..', 'content');
  const swaggerOutputDir = path.join(outputDir, 'api');
  fs.mkdirSync(swaggerOutputDir, { recursive: true });

  const swaggerOutputPath = path.join(swaggerOutputDir, 'swagger.json');
  fs.writeFileSync(swaggerOutputPath, JSON.stringify(swaggerData, null, 2));
  console.log('File saved to ./content/api/swagger.json');

  await generateFiles({
    input: openapi,
    output: './content/docs/distributor/',
    includeDescription: true,
  });
}

main().catch(console.error);
