# Tech radar

<script src="https://d3js.org/d3.v4.min.js"></script>

<script src="https://zalando.github.io/tech-radar/release/radar-0.11.js"></script>

<svg id="radar"></svg>

<script>
radar_visualization({
  // title: "Tech Radar",
  quadrants: [
    { name: "Methods" },
    { name: "Tools" },
    { name: "Langages & Frameworks" },
    { name: "Other" }
  ],
  rings: [
    { name: "Poulet", color: "#5ba300" },
    { name: "Good", color: "#009eb0" },
    { name: "Meh", color: "#c7ba00" },
    { name: "Nope", color: "#e09b96" }
  ],
  entries: [
    { label: "EventStorming", quadrant: 0, ring: 1, moved: 0, link: "https://www.eventstorming.com/" },
    { label: "Team Topologies", quadrant: 0, ring: 1, moved: 0, link: "https://teamtopologies.com/" },
    { label: "ADR", quadrant: 0, ring: 0, moved: 0, link: "https://adr.github.io/" },
    { label: "Diátaxis", quadrant: 0, ring: 1, moved: 0, link: "https://diataxis.fr/" },
    { label: "Zettelkasten", quadrant: 0, ring: 2, moved: 0, link: "https://zettelkasten.de/" },
    { label: "go-task", quadrant: 1, ring: 0, moved: 0, link: "https://taskfile.dev/" },
    { label: "treefmt", quadrant: 1, ring: 0, moved: 0, link: "https://github.com/numtide/treefmt" },
    { label: "lefthook", quadrant: 1, ring: 0, moved: 0, link: "https://evilmartians.com/chronicles/lefthook-succession-of-git-hooks" },
    { label: "Just", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/casey/just" },
    { label: "VHS", quadrant: 1, ring: 2, moved: 0, link: "https://github.com/charmbracelet/vhs" },
    { label: "mdBook", quadrant: 1, ring: 1, moved: 0, link: "https://rust-lang.github.io/mdBook/" },
    { label: "GitHub Actions", quadrant: 1, ring: 1, moved: 0, link: "https://github.com/features/actions" },
    { label: "GitLab CI/CD", quadrant: 1, ring: 1, moved: 0, link: "https://docs.gitlab.com/ee/ci/" },
    { label: "CircleCI", quadrant: 1, ring: 1, moved: 0, link: "https://circleci.com/" },
    { label: "Jenkins", quadrant: 1, ring: 3, moved: 0, link: "https://www.jenkins.io/" },
    { label: "Travis CI", quadrant: 1, ring: 2, moved: 0, link: "https://travis-ci.org/" },
    { label: "Argo CD", quadrant: 1, ring: 1, moved: 0, link: "https://argo-cd.readthedocs.io/" },
    { label: "Drone CI", quadrant: 1, ring: 1, moved: 0, link: "https://drone.io/" },
    { label: "Terraform-docs", quadrant: 1, ring: 1, moved: 0, link: "https://terraform-docs.io/" },
    { label: "Rust", quadrant: 2, ring: 0, moved: 0, link: "https://www.rust-lang.org/" },
    { label: "Go", quadrant: 2, ring: 0, moved: 0, link: "https://golang.org/" },
    { label: "Python", quadrant: 2, ring: 1, moved: 0, link: "https://www.python.org/" },
    { label: "Bash", quadrant: 2, ring: 1, moved: 0, link: "https://www.gnu.org/software/bash/" }
  ]
});
</script>
