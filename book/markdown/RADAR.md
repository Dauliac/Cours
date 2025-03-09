# Tech radar open source courses

<!-- Intégration des scripts nécessaires -->

<script src="https://d3js.org/d3.v4.min.js"></script>

<script src="https://zalando.github.io/tech-radar/release/radar-0.11.js"></script>

<!-- Conteneur pour le radar -->

<svg id="radar"></svg>

<!-- Script de configuration du radar -->

<script>
fetch('./assets/radar.json').then(function(response) {
  return response.json();
}).then(function(data) {
  radar_visualization({
    repo_url: "https://github.com/zalando/tech-radar",
    title: "Zalando Tech Radar",
    date: data.date,
    quadrants: [
      { name: "Languages" },
      { name: "Infrastructure" },
      { name: "Datastores" },
      { name: "Data Management" },
    ],
    rings: [
      { name: "ADOPT", color: "#5ba300" },
      { name: "TRIAL", color: "#009eb0" },
      { name: "ASSESS", color: "#c7ba00" },
      { name: "HOLD", color: "#e09b96" },
    ],
    entries: data.entries
  });
}).catch(function(err) {
  console.log('Error loading config.json', err);
});
</script>

radar_visualization({
svg_id: "radar",
// width: 1200,
// height: 800,
// colors: {
//   background: "#fff",
//   grid: "#bbb",
//   inactive: "#ddd"
// },
title: "Courses Tech radar",
quadrants: \[
{ name: "Techniques" },
{ name: "Outils" },
{ name: "Plateformes" },
{ name: "Langages & Frameworks" }
\],
rings: \[
{ name: "Incredible", color: "#5ba300" },
{ name: "Cool", color: "#009eb0" },
{ name: "Why not", color: "#c7ba00" },
{ name: "Nope", color: "#e09b96" }
\],
entries: data.entries
entries: \[
// Techniques
{ label: "EventStorming", quadrant: 0, ring: 1, moved: 0 },
{ label: "Team Topologies", quadrant: 0, ring: 1, moved: 0 },
{ label: "CD Pull", quadrant: 0, ring: 2, moved: 0 },
{ label: "CD Push", quadrant: 0, ring: 2, moved: 0 },
{ label: "ADR", quadrant: 0, ring: 0, moved: 0 },
{ label: "Diátaxis", quadrant: 0, ring: 1, moved: 0 },
{ label: "Zettelkasten", quadrant: 0, ring: 2, moved: 0 },

```
// Outils
{ label: "go-task", quadrant: 1, ring: 0, moved: 0 },
{ label: "treefmt", quadrant: 1, ring: 0, moved: 0 },
{ label: "lefthook", quadrant: 1, ring: 1, moved: 0 },
{ label: "Just", quadrant: 1, ring: 0, moved: 0 },
{ label: "Tech Radar", quadrant: 1, ring: 0, moved: 0 },
{ label: "VHS", quadrant: 1, ring: 2, moved: 0 },
{ label: "mdBook", quadrant: 1, ring: 1, moved: 0 },
{ label: "mdBook cmd-run", quadrant: 1, ring: 2, moved: 0 },
{ label: "rustdoc", quadrant: 1, ring: 1, moved: 0 },
{ label: "Vale", quadrant: 1, ring: 1, moved: 0 },
{ label: "Doc Detective", quadrant: 1, ring: 2, moved: 0 },
{ label: "mdformat", quadrant: 1, ring: 1, moved: 0 },
{ label: "GitHub Actions", quadrant: 1, ring: 0, moved: 0 },
{ label: "GitLab CI/CD", quadrant: 1, ring: 0, moved: 0 },
{ label: "CircleCI", quadrant: 1, ring: 1, moved: 0 },
{ label: "Jenkins", quadrant: 1, ring: 2, moved: 0 },
{ label: "Travis CI", quadrant: 1, ring: 2, moved: 0 },
{ label: "Spinnaker", quadrant: 1, ring: 2, moved: 0 },
{ label: "Argo CD", quadrant: 1, ring: 1, moved: 0 },
{ label: "Drone CI", quadrant: 1, ring: 1, moved: 0 },
{ label: "Tekton", quadrant: 1, ring: 1, moved: 0 },
{ label: "Concourse CI", quadrant: 1, ring: 2, moved: 0 },
{ label: "terraform-docs", quadrant: 1, ring: 1, moved: 0 },
{ label: "trivy", quadrant: 1, ring: 1, moved: 0 },
{ label: "grype", quadrant: 1, ring: 1, moved: 0 },
{ label: "kubeconform", quadrant: 1, ring: 2, moved: 0 },
{ label: "ansible-lint", quadrant: 1, ring: 2, moved: 0 },
{ label: "ansible molecule", quadrant: 1, ring: 2, moved: 0 },
{ label: "dotenv-linter", quadrant: 1, ring: 2, moved: 0 },
{ label: "reviewdog", quadrant: 1, ring: 2, moved: 0 },
{ label: "convco", quadrant: 1, ring: 2, moved: 0 },
{ label: "trufflehog", quadrant: 1, ring: 2, moved: 0 },
{ label: "act", quadrant: 1, ring: 2, moved: 0 },
{ label: "nix flake", quadrant: 1, ring: 1, moved: 0 },
{ label: "k3s", quadrant: 1, ring: 2, moved: 0 },
{ label: "vagrant", quadrant: 1, ring: 2, moved: 0 },
{ label: "Makefile", quadrant: 1, ring: 0, moved: 0 },

// Langages & Frameworks
{ label: "Rust", quadrant: 2, ring: 0, moved: 0 },
{ label: "Go", quadrant: 2, ring: 0, moved: 0 },
{ label: "Python", quadrant: 2, ring: 0, moved: 0 },
{ label: "Bash", quadrant: 2, ring: 0, moved: 0 }
```

\]

});
</script>
