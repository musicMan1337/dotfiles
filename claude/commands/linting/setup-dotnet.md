---
name: linting:setup-dotnet
model: opus
description: Set up .NET analyzers, .editorconfig, and strict code analysis for a C#/.NET repo. Triggers on: setup dotnet linting, add analyzers, configure dotnet analysis, dotnet lint setup, setup csharp linting, add code analysis
---

# Linting Setup — .NET / C#

You are setting up a strict, modern code analysis and style enforcement configuration for a .NET/C# project. Your goal is maximum strictness with build-time enforcement — warnings ARE errors. This follows the same philosophy as the reference setup used in our Core API.

## Process

### Phase 1 — Detect the Solution Structure

Spawn a **Haiku sub-agent** to analyze the repo and report:
- Solution file (`.sln`) location and which projects it includes
- Target framework(s) across projects (net8.0, net9.0, net10.0, etc.)
- Project types (Web API, class library, console, test, Blazor, etc.)
- Existing analysis setup — check for:
  - `Directory.Build.props` / `Directory.Build.targets`
  - `Directory.Packages.props` (central package management)
  - `.editorconfig`
  - `.globalconfig`
  - `.ruleset` files (legacy — should be migrated)
  - Any existing analyzer NuGet packages in `.csproj` files
- NuGet package management approach (PackageReference in each csproj vs central)
- Test projects and test frameworks used

### Phase 2 — Research Modern Best Practices

Spawn **WebSearch sub-agents** in parallel:
1. "dotnet code analysis analyzers best practices 2025" — current analyzer landscape
2. "SonarAnalyzer.CSharp vs Roslynator vs Meziantou 2025 comparison" — pick the best analyzers
3. ".editorconfig C# strict settings dotnet 2025" — latest .editorconfig rules
4. "Directory.Build.props AnalysisLevel AnalysisMode best practices" — build-level enforcement

Use research to validate and enhance the reference configuration below.

### Phase 3 — Set Up Build-Level Analysis

#### `Directory.Build.props`

If one exists, merge these settings into it. If not, create it in the solution root (same directory as the `.sln` file).

**Reference configuration (adapt to detected target framework):**

```xml
<Project>
  <PropertyGroup>
    <AnalysisLevel>latest</AnalysisLevel>
    <AnalysisMode>All</AnalysisMode>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <CodeAnalysisTreatWarningsAsErrors>true</CodeAnalysisTreatWarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <!-- Analyzer packages — applied to ALL projects -->
  <ItemGroup>
    <PackageReference Include="SonarAnalyzer.CSharp" PrivateAssets="all" />
    <!-- Add other analyzers based on research (e.g., Meziantou.Analyzer, Roslynator.Analyzers) -->
  </ItemGroup>
</Project>
```

Key settings explained:
- **`AnalysisLevel: latest`** — enables the newest analyzer rules for the SDK version
- **`AnalysisMode: All`** — enables ALL analysis rules by default (most aggressive mode)
- **`TreatWarningsAsErrors: true`** — no warnings allowed; everything is an error or explicitly suppressed
- **`CodeAnalysisTreatWarningsAsErrors: true`** — ensures analyzer warnings are also errors
- **`EnforceCodeStyleInBuild: true`** — IDE style rules (IDE0xxx) are enforced during `dotnet build`, not just in IDE

If the project uses central package management (`Directory.Packages.props`), put the analyzer version there instead and use `<PackageReference Include="SonarAnalyzer.CSharp" />` without a version in Directory.Build.props.

#### Central Package Management

If `Directory.Packages.props` exists, add analyzer versions there:
```xml
<PackageVersion Include="SonarAnalyzer.CSharp" Version="LATEST" />
```

If it doesn't exist but the project has 3+ projects, suggest setting it up.

### Phase 4 — Create `.editorconfig`

Create a comprehensive `.editorconfig` in the solution root. This is the heart of the style enforcement.

**Reference structure (adapt based on research and project needs):**

```ini
root = true

# Global defaults
[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
max_line_length = 120

# C# specific
[*.cs]

#### Core Style Rules — severity: error ####

# Expression-level preferences
dotnet_style_collection_initializer = true:error
dotnet_style_explicit_tuple_names = true:error
dotnet_style_null_propagation = true:error
dotnet_style_object_initializer = true:error
dotnet_style_prefer_compound_assignment = true:error
dotnet_style_prefer_conditional_expression_over_assignment = true:warning
dotnet_style_prefer_conditional_expression_over_return = true:warning
dotnet_style_prefer_simplified_boolean_expressions = true:error
dotnet_style_prefer_simplified_interpolation = true:error

# Modifier preferences
dotnet_style_require_accessibility_modifiers = for_non_interface_members:error
dotnet_style_readonly_field = true:error
csharp_prefer_static_local_function = true:error

# Parameter preferences
dotnet_code_quality_unused_parameters = all:error

# Namespace and using preferences
csharp_style_namespace_declarations = file_scoped:error
dotnet_sort_system_directives_first = true:error
csharp_using_directive_placement = outside_namespace:error

# Type preferences
dotnet_style_predefined_type_for_locals_parameters_members = true:error
dotnet_style_predefined_type_for_member_access = true:error

# Code block preferences
csharp_prefer_braces = true:error
csharp_prefer_simple_using_statement = true:error
csharp_style_prefer_method_group_conversion = true:error

# var preferences — enforce var everywhere
csharp_style_var_for_built_in_types = true:error
csharp_style_var_when_type_is_apparent = true:error
csharp_style_var_elsewhere = true:error

# Pattern matching
csharp_style_prefer_pattern_matching = true:error
csharp_style_prefer_not_pattern = true:error
csharp_style_prefer_switch_expression = true:error
csharp_style_pattern_matching_over_as_with_null_check = true:error
csharp_style_pattern_matching_over_is_with_cast_check = true:error

# Expression-bodied members
csharp_style_expression_bodied_methods = when_on_single_line:suggestion
csharp_style_expression_bodied_constructors = false:suggestion
csharp_style_expression_bodied_operators = when_on_single_line:suggestion
csharp_style_expression_bodied_properties = true:suggestion
csharp_style_expression_bodied_accessors = true:suggestion
csharp_style_expression_bodied_lambdas = true:suggestion
csharp_style_expression_bodied_local_functions = when_on_single_line:suggestion

# Inlined variable declarations
csharp_style_inlined_variable_declaration = true:error
csharp_style_deconstructed_variable_declaration = true:suggestion
csharp_prefer_simple_default_expression = true:error
csharp_style_prefer_local_over_anonymous_function = true:error

# New line preferences
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_new_line_before_members_in_object_initializers = true
csharp_new_line_before_members_in_anonymous_types = true
csharp_new_line_between_query_expression_clauses = true

# Indentation
csharp_indent_case_contents = true
csharp_indent_switch_labels = true
csharp_indent_block_contents = true
csharp_indent_braces = false

# Spacing
csharp_space_after_cast = false
csharp_space_after_keywords_in_control_flow_statements = true
csharp_space_between_method_declaration_parameter_list_parentheses = false
csharp_space_between_method_call_parameter_list_parentheses = false
csharp_space_before_colon_in_inheritance_clause = true
csharp_space_after_colon_in_inheritance_clause = true
csharp_space_around_binary_operators = before_and_after

#### Naming Conventions ####
dotnet_naming_rule.interface_should_be_begins_with_i.severity = suggestion
dotnet_naming_rule.interface_should_be_begins_with_i.symbols = interface
dotnet_naming_rule.interface_should_be_begins_with_i.style = begins_with_i
dotnet_naming_symbols.interface.applicable_kinds = interface
dotnet_naming_style.begins_with_i.required_prefix = I
dotnet_naming_style.begins_with_i.capitalization = pascal_case

dotnet_naming_rule.types_should_be_pascal_case.severity = suggestion
dotnet_naming_rule.types_should_be_pascal_case.symbols = types
dotnet_naming_rule.types_should_be_pascal_case.style = pascal_case_style
dotnet_naming_symbols.types.applicable_kinds = class, struct, interface, enum, delegate
dotnet_naming_style.pascal_case_style.capitalization = pascal_case

dotnet_naming_rule.methods_should_be_pascal_case.severity = suggestion
dotnet_naming_rule.methods_should_be_pascal_case.symbols = methods
dotnet_naming_rule.methods_should_be_pascal_case.style = pascal_case_style
dotnet_naming_symbols.methods.applicable_kinds = method

#### Suppressed Rules ####
# Suppress rules that conflict with domain patterns.
# Add project-specific suppressions below as needed.

# Example: suppress for specific file patterns
# [**/*Response.cs]
# dotnet_diagnostic.CA1819.severity = none
# dotnet_diagnostic.CA2227.severity = none

#### XML / config files ####
[*.{xml,csproj,props,targets}]
indent_size = 2

[*.json]
indent_size = 2

[*.{yml,yaml}]
indent_size = 2
```

**Important:** This is a starting template. After the build validation in Phase 6, you will need to suppress rules that generate excessive noise for the specific codebase. The reference Core repo suppresses many CA and S rules — but those suppressions should be earned by the codebase, not copied blindly.

### Phase 5 — Clean Up Legacy Config

If any of these exist, migrate them and remove:
- `.ruleset` files → migrate rules to `.editorconfig` `dotnet_diagnostic.XXXX.severity` entries
- `stylecop.json` → migrate to `.editorconfig` rules
- `.globalconfig` → merge into `.editorconfig` (unless there's a reason to keep separate)
- Per-project analyzer settings in `.csproj` → move to `Directory.Build.props`

### Phase 6 — Validate

Run `dotnet build` on the solution. Expect a LOT of errors since we have `TreatWarningsAsErrors = true` with `AnalysisMode = All`.

**Triage the errors:**

1. **Configuration/compatibility errors** (package version conflicts, missing dependencies):
   - Spawn a **WebSearch sub-agent** to search for the exact error
   - Apply the fix
   - Do NOT remove analyzer packages without searching first

2. **Analyzer rule violations in existing code:**
   - Report the total count and top categories to the user
   - Do NOT auto-fix code — this is informational
   - Suggest that the user can suppress specific rules in `.editorconfig` if needed, using `dotnet_diagnostic.XXXX.severity = none`
   - For rules generating 50+ violations across the codebase, mention them specifically as candidates for suppression or gradual adoption

3. **Rules that are genuinely inapplicable to the project pattern:**
   - If research or the error context clearly shows a rule doesn't apply (e.g., CA1812 "avoid uninstantiated internal classes" for DI-registered services), suppress it in `.editorconfig` with a comment explaining why

## Analyzer Package Guidance

**Always include:**
- **SonarAnalyzer.CSharp** — comprehensive, well-maintained, catches real bugs

**Consider based on research (check latest recommendations):**
- **Meziantou.Analyzer** — opinionated but catches things others miss (async patterns, string comparisons, etc.)
- **Roslynator.Analyzers** — large rule set, good refactoring suggestions
- **Microsoft.CodeAnalysis.NetAnalyzers** — built into SDK, but AnalysisMode: All enables them all

**For test projects specifically:**
- Consider suppressing strict rules that don't apply to tests (e.g., CA1707 for test method naming with underscores)
- Add test-specific suppressions in a `[*Tests*/**/*.cs]` section in .editorconfig

## Gotchas

- **`AnalysisMode: All` is aggressive.** It enables every built-in analyzer rule. Combined with `TreatWarningsAsErrors`, an existing codebase WILL fail to build. This is intentional — the user should then triage and suppress rules they don't want rather than starting permissive.
- **`EnforceCodeStyleInBuild: true` is the key setting most teams miss.** Without it, IDE style rules (IDE0xxx) only show in the editor and are ignored by `dotnet build` and CI. With it, style IS the build.
- **Central package management (`ManagePackageVersionsCentrally`)** is the modern approach for multi-project solutions. If the repo doesn't use it yet, mention it as a recommendation but don't force it — it's a separate migration.
- **Test projects need special treatment.** Rules like CA1707 (identifiers shouldn't contain underscores) conflict with common test naming conventions (`Should_DoThing_When_Condition`). Add targeted suppressions.
- **SonarAnalyzer rules (S prefix) overlap with CA rules.** Some rules check the same thing. If you get duplicate diagnostics, suppress the less informative one.
- **`.editorconfig` severity levels matter:**
  - `error` = build fails (use for rules you absolutely want enforced)
  - `warning` = shows up but doesn't fail build... UNLESS `TreatWarningsAsErrors` is true, in which case it also fails
  - `suggestion` = IDE only, never fails build
  - `none` = completely disabled
  Since we use `TreatWarningsAsErrors`, there's effectively no difference between `error` and `warning`. Use `:error` for rules you want and `:none` for rules you don't. Use `:suggestion` for "nice to have" style preferences that shouldn't block builds.
- **Don't blindly copy suppressions from other projects.** The reference Core repo suppresses ~40+ rules, but those suppressions were earned over time for specific patterns (request handlers, response DTOs, etc.). Start with zero suppressions and add them as the build tells you what's needed.
- **`dotnet_diagnostic` entries in `.editorconfig` override `AnalysisMode`.** This is the intended customization mechanism — turn everything on globally, then selectively turn off what doesn't apply.
- **Per-file/folder suppressions in `.editorconfig`** use glob patterns like `[**/Migrations/*.cs]`. Use these for generated code, legacy code, or domain-specific patterns rather than suppressing globally.
- **Legacy `.ruleset` files** still work but are deprecated. If you find one, migrate its rules to `.editorconfig` `dotnet_diagnostic` entries. Don't maintain both.
