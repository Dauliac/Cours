// Build and containerize the demo Rust binary
package main

import (
	"context"
	"dagger/demo/internal/dagger"
)

type Demo struct{}

// Build the Rust project and return a minimal scratch container with the static binary
func (m *Demo) Build(ctx context.Context, source *dagger.Directory) *dagger.Container {
	// Builder stage: install mise, then use Taskfile tasks (same as developer env)
	binary := dag.Container().
		From("ubuntu:24.04").
		WithExec([]string{"apt-get", "update"}).
		WithExec([]string{"apt-get", "install", "-y", "curl", "musl-tools", "build-essential"}).
		WithExec([]string{"sh", "-c", "curl https://mise.run | sh"}).
		WithEnvVariable("PATH", "/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin").
		WithWorkdir("/app").
		WithMountedCache("/root/.cargo/registry", dag.CacheVolume("cargo-registry")).
		WithMountedCache("/app/target", dag.CacheVolume("rust-target-musl")).
		WithDirectory("/app", source).
		WithEnvVariable("MISE_YES", "1").
		WithExec([]string{"mise", "exec", "--", "task", "install"}).
		WithExec([]string{"mise", "exec", "--", "task", "build:static"}).
		WithExec([]string{"cp", "/app/target/x86_64-unknown-linux-musl/release/demo", "/demo"}).
		File("/demo")

	// Minimal passwd/group files for non-root user
	etc := dag.Directory().
		WithNewFile("passwd", "nobody:x:65534:65534:nobody:/:/nonexistent").
		WithNewFile("group", "nobody:x:65534:")

	// Runtime stage: scratch with only the static binary, non-root
	return dag.Container().
		WithFile("/demo", binary).
		WithFile("/etc/passwd", etc.File("passwd")).
		WithFile("/etc/group", etc.File("group")).
		WithUser("65534").
		WithEntrypoint([]string{"/demo"})
}

// Build and publish the container image to a registry
func (m *Demo) Publish(ctx context.Context, source *dagger.Directory, address string) (string, error) {
	return m.Build(ctx, source).Publish(ctx, address)
}
