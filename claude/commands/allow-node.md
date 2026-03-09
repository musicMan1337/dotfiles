---
model: haiku
allowed-tools: Bash, Read, Edit
description: Add Node/TypeScript allow and deny permission rules to local project settings
---

Add a comprehensive set of Node.js / TypeScript permission rules to `.claude/settings.local.json` in the current project.

## Rules to add

### Allow
```
Bash(cat *)
Bash(cp *)
Bash(curl *)
Bash(docker *)
Bash(docker-compose *)
Bash(echo *)
Bash(env *)
Bash(export *)
Bash(find *)
Bash(git add *)
Bash(git branch *)
Bash(git checkout *)
Bash(git commit *)
Bash(git diff *)
Bash(git log *)
Bash(git stash *)
Bash(git status)
Bash(grep *)
Bash(grep:*)
Bash(jest *)
Bash(jq *)
Bash(kill *)
Bash(knex *)
Bash(ls *)
Bash(lsof *)
Bash(mkdir *)
Bash(mocha *)
Bash(mongosh *)
Bash(mv *)
Bash(mysql *)
Bash(node *)
Bash(nodemon *)
Bash(npm init *)
Bash(npm install *)
Bash(npm run *)
Bash(npm test *)
Bash(npx *)
Bash(pkill *)
Bash(prisma *)
Bash(psql *)
Bash(redis-cli *)
Bash(sequelize *)
Bash(touch *)
Bash(tsc *)
Bash(ts-node *)
Bash(vitest *)
Bash(which *)
Edit(.eslintrc*)
Edit(.gitignore)
Edit(.prettierrc*)
Edit(config/**)
Edit(controllers/**)
Edit(docker-compose*)
Edit(Dockerfile)
Edit(jest.config*)
Edit(middleware/**)
Edit(models/**)
Edit(nodemon.json)
Edit(package-lock.json)
Edit(package.json)
Edit(postcss.config*)
Edit(public/**)
Edit(README.md)
Edit(routes/**)
Edit(scripts/**)
Edit(services/**)
Edit(src/**)
Edit(tailwind.config*)
Edit(tests/**)
Edit(tsconfig.json)
Edit(utils/**)
Edit(views/**)
Edit(vite.config*)
Edit(webpack.config*)
Read(**)
Skill(git-commit)
```

### Deny
```
Bash(chmod 777 *)
Bash(git push --force *)
Bash(git push *)
Bash(rm -rf /)
Bash(rm -rf ~*)
Bash(sudo *)
Edit(.env.*)
Edit(.env)
Edit(*.cert)
Edit(*.key)
Edit(*.pem)
Edit(node_modules/**)
```

## Instructions

1. Ensure `.claude/` directory exists in the project root.
2. If `.claude/settings.local.json` does not exist, create it with the allow and deny rules above.
3. If it already exists, merge the rules into the existing allow and deny arrays, avoiding duplicates.
4. Use `jq` to handle the JSON manipulation.
5. Print a short confirmation with the count of allow and deny rules in the final file.
