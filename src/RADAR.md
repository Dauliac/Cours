# Tech radar

<script src="https://d3js.org/d3.v4.min.js"></script>

<script src="https://zalando.github.io/tech-radar/release/radar-0.11.js"></script>

<svg id="radar"></svg>

<script>
radar_visualization({
  // title: "Tech Radar",
  width: 1500,
  height: 1900,
  quadrants: [
    { name: "Methods" },
    { name: "Tools" },
    { name: "Languages & Frameworks" },
    { name: "Other" }
  ],
  rings: [
    { name: "Poulet", color: "#5ba300" },
    { name: "Good", color: "#009eb0" },
    { name: "Meh", color: "#c7ba00" },
    { name: "Nope", color: "#e09b96" }
  ],
  entries: [
    // Methods
    { label: "EventStorming", quadrant: 0, ring: 1, moved: 0, link: "https://www.eventstorming.com/" },
    { label: "Team Topologies", quadrant: 0, ring: 1, moved: 0, link: "https://teamtopologies.com/" },
    { label: "ADR", quadrant: 0, ring: 0, moved: 0, link: "https://adr.github.io/" },
    { label: "Diátaxis", quadrant: 0, ring: 1, moved: 0, link: "https://diataxis.fr/" },
    { label: "Zettelkasten", quadrant: 0, ring: 2, moved: 0, link: "https://zettelkasten.de/" },
    { label: "Trunk Based Dev", quadrant: 0, ring: 0, moved: 0, link: "https://trunkbaseddevelopment.com/" },
    { label: "GitFlow", quadrant: 0, ring: 3, moved: 0, link: "https://nvie.com/posts/a-successful-git-branching-model/" },
    { label: "GitOps", quadrant: 0, ring: 0, moved: 0, link: "https://opengitops.dev/" },
    { label: "Infrastructure as Code", quadrant: 0, ring: 0, moved: 0, link: "https://www.pulumi.com/what-is/what-is-infrastructure-as-code/" },
    { label: "Conventional Commits", quadrant: 0, ring: 0, moved: 0, link: "https://www.conventionalcommits.org/" },
    { label: "Semantic Versioning", quadrant: 0, ring: 0, moved: 0, link: "https://semver.org/" },
    { label: "DevOps", quadrant: 0, ring: 0, moved: 0, link: "https://cloud.google.com/devops" },
    { label: "SRE", quadrant: 0, ring: 1, moved: 0, link: "https://sre.google/" },
    { label: "Platform Engineering", quadrant: 0, ring: 1, moved: 0, link: "https://platformengineering.org/" },
    { label: "Twelve-Factor App", quadrant: 0, ring: 0, moved: 0, link: "https://12factor.net/" },
    { label: "Immutable Infra", quadrant: 0, ring: 0, moved: 0, link: "https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure" },
    { label: "Feature Flags", quadrant: 0, ring: 1, moved: 0, link: "https://martinfowler.com/articles/feature-toggles.html" },
    { label: "Chaos Engineering", quadrant: 0, ring: 2, moved: 0, link: "https://principlesofchaos.org/" },

    // Tools — Task runners & Build systems
    { label: "go-task", quadrant: 1, ring: 0, moved: 0, link: "https://taskfile.dev/" },
    { label: "Just", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/casey/just" },
    { label: "Make", quadrant: 1, ring: 2, moved: 0, link: "https://www.gnu.org/software/make/" },
    { label: "mise", quadrant: 1, ring: 0, moved: 0, link: "https://mise.jdx.dev/" },
    { label: "Nix", quadrant: 1, ring: 0, moved: 0, link: "https://nixos.org/" },
    { label: "Guix", quadrant: 1, ring: 2, moved: 0, link: "https://guix.gnu.org/" },
    { label: "Dagger", quadrant: 1, ring: 1, moved: 0, link: "https://dagger.io/" },
    { label: "Earthly", quadrant: 1, ring: 1, moved: 0, link: "https://earthly.dev/" },
    { label: "Buck2", quadrant: 1, ring: 2, moved: 0, link: "https://buck2.build/" },
    { label: "Bazel", quadrant: 1, ring: 2, moved: 0, link: "https://bazel.build/" },
    { label: "Pants", quadrant: 1, ring: 2, moved: 0, link: "https://www.pantsbuild.org/" },
    { label: "devenv", quadrant: 1, ring: 0, moved: 0, link: "https://devenv.sh/" },

    // Tools — Git hooks & Code quality
    { label: "lefthook", quadrant: 1, ring: 0, moved: 0, link: "https://evilmartians.com/chronicles/lefthook-succession-of-git-hooks" },
    { label: "hk", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/jdx/hk" },
    { label: "pre-commit", quadrant: 1, ring: 2, moved: 0, link: "https://pre-commit.com/" },
    { label: "Husky", quadrant: 1, ring: 2, moved: 0, link: "https://typicode.github.io/husky/" },
    { label: "treefmt", quadrant: 1, ring: 0, moved: 0, link: "https://github.com/numtide/treefmt" },
    { label: "EditorConfig", quadrant: 1, ring: 1, moved: 0, link: "https://editorconfig.org/" },

    // Tools — CI/CD
    { label: "GitHub Actions", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/features/actions" },
    { label: "GitLab CI/CD", quadrant: 1, ring: 1, moved: 0, link: "https://docs.gitlab.com/ee/ci/" },
    { label: "CircleCI", quadrant: 1, ring: 1, moved: 0, link: "https://circleci.com/" },
    { label: "Jenkins", quadrant: 1, ring: 3, moved: 0, link: "https://www.jenkins.io/" },
    { label: "Travis CI", quadrant: 1, ring: 2, moved: 0, link: "https://travis-ci.org/" },
    { label: "Drone CI", quadrant: 1, ring: 1, moved: 0, link: "https://drone.io/" },
    { label: "Tekton", quadrant: 1, ring: 2, moved: 0, link: "https://tekton.dev/" },
    { label: "Buildkite", quadrant: 1, ring: 1, moved: 0, link: "https://buildkite.com/" },
    { label: "Forgejo Actions", quadrant: 1, ring: 1, moved: 0, link: "https://forgejo.org/" },

    // Tools — GitOps & Deployment
    { label: "Argo CD", quadrant: 1, ring: 1, moved: 0, link: "https://argo-cd.readthedocs.io/" },
    { label: "Flux CD", quadrant: 1, ring: 1, moved: 0, link: "https://fluxcd.io/" },
    { label: "Helm", quadrant: 1, ring: 1, moved: 0, link: "https://helm.sh/" },
    { label: "Kustomize", quadrant: 1, ring: 1, moved: 0, link: "https://kustomize.io/" },
    { label: "Timoni", quadrant: 1, ring: 2, moved: 0, link: "https://timoni.sh/" },

    // Tools — Local dev & inner loop
    { label: "Skaffold", quadrant: 1, ring: 1, moved: 0, link: "https://skaffold.dev/" },
    { label: "Tilt", quadrant: 1, ring: 1, moved: 0, link: "https://tilt.dev/" },
    { label: "DevSpace", quadrant: 1, ring: 2, moved: 0, link: "https://devspace.sh/" },
    { label: "Telepresence", quadrant: 1, ring: 2, moved: 0, link: "https://www.telepresence.io/" },

    // Tools — Containers & Orchestration
    { label: "Docker", quadrant: 1, ring: 1, moved: 0, link: "https://www.docker.com/" },
    { label: "Podman", quadrant: 1, ring: 0, moved: 0, link: "https://podman.io/" },
    { label: "Buildah", quadrant: 1, ring: 1, moved: 0, link: "https://buildah.io/" },
    { label: "Kubernetes", quadrant: 1, ring: 1, moved: 0, link: "https://kubernetes.io/" },
    { label: "k3s", quadrant: 1, ring: 1, moved: 0, link: "https://k3s.io/" },
    { label: "Nomad", quadrant: 1, ring: 2, moved: 0, link: "https://www.nomadproject.io/" },
    { label: "Docker Compose", quadrant: 1, ring: 1, moved: 0, link: "https://docs.docker.com/compose/" },
    { label: "containerd", quadrant: 1, ring: 1, moved: 0, link: "https://containerd.io/" },

    // Tools — IaC & Provisioning
    { label: "Terraform", quadrant: 1, ring: 1, moved: 0, link: "https://www.terraform.io/" },
    { label: "OpenTofu", quadrant: 1, ring: 0, moved: 0, link: "https://opentofu.org/" },
    { label: "Pulumi", quadrant: 1, ring: 1, moved: 0, link: "https://www.pulumi.com/" },
    { label: "Ansible", quadrant: 1, ring: 2, moved: 0, link: "https://www.ansible.com/" },
    { label: "Terraform-docs", quadrant: 1, ring: 1, moved: 0, link: "https://terraform-docs.io/" },
    { label: "Terragrunt", quadrant: 1, ring: 2, moved: 0, link: "https://terragrunt.gruntwork.io/" },

    // Tools — Versioning & Release
    { label: "release-please", quadrant: 1, ring: 0, moved: 0, link: "https://github.com/googleapis/release-please" },
    { label: "semantic-release", quadrant: 1, ring: 1, moved: 0, link: "https://semantic-release.gitbook.io/" },
    { label: "changie", quadrant: 1, ring: 1, moved: 0, link: "https://changie.dev/" },
    { label: "git-cliff", quadrant: 1, ring: 1, moved: 0, link: "https://git-cliff.org/" },

    // Tools — Security & Scanning
    { label: "Trivy", quadrant: 1, ring: 0, moved: 0, link: "https://trivy.dev/" },
    { label: "Grype", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/anchore/grype" },
    { label: "Cosign", quadrant: 1, ring: 1, moved: 0, link: "https://docs.sigstore.dev/cosign/overview/" },
    { label: "SOPS", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/getsops/sops" },
    { label: "gitleaks", quadrant: 1, ring: 0, moved: 0, link: "https://gitleaks.io/" },
    { label: "age", quadrant: 1, ring: 1, moved: 0, link: "https://age-encryption.org/" },

    // Tools — Documentation & Diagrams
    { label: "mdBook", quadrant: 1, ring: 1, moved: 0, link: "https://rust-lang.github.io/mdBook/" },
    { label: "VHS", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/charmbracelet/vhs" },
    { label: "Marp", quadrant: 1, ring: 1, moved: 0, link: "https://marp.app/" },
    { label: "Mermaid", quadrant: 1, ring: 0, moved: 0, link: "https://mermaid.js.org/" },
    { label: "D2", quadrant: 1, ring: 1, moved: 0, link: "https://d2lang.com/" },
    { label: "draw.io", quadrant: 1, ring: 1, moved: 0, link: "https://www.drawio.com/" },
    { label: "Mark", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/kovetskiy/mark" },
    { label: "Docusaurus", quadrant: 1, ring: 1, moved: 0, link: "https://docusaurus.io/" },
    { label: "Astro", quadrant: 1, ring: 1, moved: 0, link: "https://astro.build/" },

    // Tools — Testing & Benchmarking
    { label: "k6", quadrant: 1, ring: 0, moved: 0, link: "https://k6.io/" },
    { label: "Testcontainers", quadrant: 1, ring: 0, moved: 0, link: "https://testcontainers.com/" },
    { label: "k3d", quadrant: 1, ring: 1, moved: 0, link: "https://k3d.io/" },
    { label: "Swagger / OpenAPI", quadrant: 1, ring: 1, moved: 0, link: "https://swagger.io/specification/" },
    { label: "Hurl", quadrant: 1, ring: 1, moved: 0, link: "https://hurl.dev/" },
    { label: "Playwright", quadrant: 1, ring: 1, moved: 0, link: "https://playwright.dev/" },
    { label: "Cypress", quadrant: 1, ring: 2, moved: 0, link: "https://www.cypress.io/" },

    // Tools — Dev environment
    { label: "direnv", quadrant: 1, ring: 0, moved: 0, link: "https://direnv.net/" },
    { label: "jq", quadrant: 1, ring: 0, moved: 0, link: "https://jqlang.github.io/jq/" },

    // Languages & Frameworks
    { label: "Rust", quadrant: 2, ring: 0, moved: 0, link: "https://www.rust-lang.org/" },
    { label: "Go", quadrant: 2, ring: 0, moved: 0, link: "https://golang.org/" },
    { label: "Python", quadrant: 2, ring: 1, moved: 0, link: "https://www.python.org/" },
    { label: "Bash", quadrant: 2, ring: 1, moved: 0, link: "https://www.gnu.org/software/bash/" },
    { label: "TypeScript", quadrant: 2, ring: 1, moved: 0, link: "https://www.typescriptlang.org/" },
    { label: "Zig", quadrant: 2, ring: 2, moved: 0, link: "https://ziglang.org/" },
    { label: "Kotlin", quadrant: 2, ring: 1, moved: 0, link: "https://kotlinlang.org/" },
    { label: "Elixir", quadrant: 2, ring: 2, moved: 0, link: "https://elixir-lang.org/" },
    { label: "Haskell", quadrant: 2, ring: 2, moved: 0, link: "https://www.haskell.org/" },
    { label: "CUE", quadrant: 2, ring: 1, moved: 0, link: "https://cuelang.org/" },
    { label: "Jsonnet", quadrant: 2, ring: 2, moved: 0, link: "https://jsonnet.org/" },
    { label: "Nickel", quadrant: 2, ring: 2, moved: 0, link: "https://nickel-lang.org/" },

    // Other — Editors & IDEs
    { label: "Neovim", quadrant: 3, ring: 0, moved: 0, link: "https://neovim.io/" },
    { label: "Helix", quadrant: 3, ring: 1, moved: 0, link: "https://helix-editor.com/" },
    { label: "Zed", quadrant: 3, ring: 1, moved: 0, link: "https://zed.dev/" },
    { label: "VS Code", quadrant: 3, ring: 1, moved: 0, link: "https://code.visualstudio.com/" },
    { label: "JetBrains", quadrant: 3, ring: 1, moved: 0, link: "https://www.jetbrains.com/" },

    // Other — OS & Distros
    { label: "NixOS", quadrant: 3, ring: 0, moved: 0, link: "https://nixos.org/" },
    { label: "Fedora", quadrant: 3, ring: 1, moved: 0, link: "https://fedoraproject.org/" },
    { label: "Arch Linux", quadrant: 3, ring: 1, moved: 0, link: "https://archlinux.org/" },
    { label: "Alpine Linux", quadrant: 3, ring: 0, moved: 0, link: "https://alpinelinux.org/" },
    { label: "Debian", quadrant: 3, ring: 1, moved: 0, link: "https://www.debian.org/" },
    { label: "Ubuntu", quadrant: 3, ring: 2, moved: 0, link: "https://ubuntu.com/" },

    // Other — VCS & Forges
    { label: "Git", quadrant: 3, ring: 0, moved: 0, link: "https://git-scm.com/" },
    { label: "Jujutsu (jj)", quadrant: 3, ring: 1, moved: 0, link: "https://martinvonz.github.io/jj/" },
    { label: "GitHub", quadrant: 3, ring: 1, moved: 0, link: "https://github.com/" },
    { label: "GitLab", quadrant: 3, ring: 1, moved: 0, link: "https://about.gitlab.com/" },
    { label: "Forgejo", quadrant: 3, ring: 1, moved: 0, link: "https://forgejo.org/" },
    { label: "Gitea", quadrant: 3, ring: 2, moved: 0, link: "https://about.gitea.com/" },

    // Other — AI & Coding Assistants
    { label: "Claude Code", quadrant: 3, ring: 0, moved: 0, link: "https://docs.anthropic.com/en/docs/claude-code" },
    { label: "Copilot", quadrant: 3, ring: 1, moved: 0, link: "https://github.com/features/copilot" },
    { label: "Cursor", quadrant: 3, ring: 1, moved: 0, link: "https://cursor.sh/" },
    { label: "Aider", quadrant: 3, ring: 1, moved: 0, link: "https://aider.chat/" },

    // Other — Misc
    { label: "WASM", quadrant: 3, ring: 1, moved: 0, link: "https://webassembly.org/" },
    { label: "eBPF", quadrant: 3, ring: 1, moved: 0, link: "https://ebpf.io/" },
    { label: "OCI", quadrant: 3, ring: 0, moved: 0, link: "https://opencontainers.org/" },
    { label: "CNCF", quadrant: 3, ring: 1, moved: 0, link: "https://www.cncf.io/" }
  ]
});
</script>
