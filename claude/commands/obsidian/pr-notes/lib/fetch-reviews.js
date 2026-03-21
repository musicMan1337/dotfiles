#!/usr/bin/env node

/**
 * Fetches PRs reviewed by the current GitHub user in the last 24 hours,
 * or a specific PR by number.
 *
 * Usage:
 *   node fetch-reviews.js                     # All reviews in last 24h
 *   node fetch-reviews.js 1234                # Specific PR number
 *   node fetch-reviews.js 1234 owner/repo     # Specific PR in a specific repo
 *
 * Output: JSON array of PR review objects.
 */

import { execSync } from "node:child_process";

function gh(cmd) {
  return JSON.parse(execSync(`gh ${cmd}`, { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 }));
}

function ghText(cmd) {
  return execSync(`gh ${cmd}`, { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 }).trim();
}

const args = process.argv.slice(2);
const prNumber = args[0] ? parseInt(args[0]) : null;
const repo = args[1] || null;

async function fetchSpecificPR(number, repo) {
  const repoFlag = repo ? `-R ${repo}` : "";
  const pr = gh(`pr view ${number} ${repoFlag} --json number,title,author,url,baseRefName,headRefName,state,body,files,reviews,comments`);

  return [{
    number: pr.number,
    title: pr.title,
    author: pr.author.login,
    url: pr.url,
    repo: repo || ghText("repo view --json nameWithOwner --jq .nameWithOwner"),
    baseBranch: pr.baseRefName,
    headBranch: pr.headRefName,
    state: pr.state,
    body: (pr.body || "").slice(0, 1000),
    filesChanged: (pr.files || []).map(f => f.path),
    reviews: (pr.reviews || []).map(r => ({
      author: r.author.login,
      state: r.state,
      body: (r.body || "").slice(0, 500),
      submittedAt: r.submittedAt,
    })),
    reviewComments: (pr.comments || []).slice(0, 20).map(c => ({
      author: c.author.login,
      body: (c.body || "").slice(0, 300),
      createdAt: c.createdAt,
    })),
  }];
}

async function fetchRecentReviews() {
  const username = ghText("api user --jq .login");
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  // Search for PRs reviewed by the user recently
  const query = `is:pr reviewed-by:${username} updated:>=${since.slice(0, 10)}`;
  let items;
  try {
    items = gh(`search prs "${query}" --json number,title,author,url,repository --limit 20`);
  } catch {
    // Fallback: check current repo's PRs
    items = [];
  }

  if (items.length === 0) {
    console.log(JSON.stringify([]));
    return;
  }

  const results = [];
  for (const item of items) {
    const repoName = item.repository?.nameWithOwner || item.repository?.name;
    if (!repoName) continue;

    try {
      const pr = gh(`pr view ${item.number} -R ${repoName} --json number,title,author,url,baseRefName,headRefName,state,body,files,reviews,comments`);

      results.push({
        number: pr.number,
        title: pr.title,
        author: pr.author.login,
        url: pr.url,
        repo: repoName,
        baseBranch: pr.baseRefName,
        headBranch: pr.headRefName,
        state: pr.state,
        body: (pr.body || "").slice(0, 1000),
        filesChanged: (pr.files || []).map(f => f.path),
        reviews: (pr.reviews || []).filter(r => r.author.login === username).map(r => ({
          author: r.author.login,
          state: r.state,
          body: (r.body || "").slice(0, 500),
          submittedAt: r.submittedAt,
        })),
        reviewComments: (pr.comments || []).filter(c => c.author.login === username).slice(0, 20).map(c => ({
          author: c.author.login,
          body: (c.body || "").slice(0, 300),
          createdAt: c.createdAt,
        })),
      });
    } catch (err) {
      console.error(`Skipping ${repoName}#${item.number}: ${err.message}`);
    }
  }

  console.log(JSON.stringify(results, null, 2));
}

async function main() {
  if (prNumber) {
    const results = await fetchSpecificPR(prNumber, repo);
    console.log(JSON.stringify(results, null, 2));
  } else {
    await fetchRecentReviews();
  }
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
