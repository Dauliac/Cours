# Get Courses

## Prerequisites

- [Nix is installed](./nix/INSTALL.md)

## Get the Project

```bash
git clone git@github.com:Dauliac/Cours.git
cd Cours
# Get path
echo $PWD/book/html/index.html
```

### Open in Browser

#### On Linux / macOS:

Open the file in your browser with:

```bash
xdg-open $PWD/book/html/index.html
```

#### On WSL (Windows Subsystem for Linux):

If you are using **WSL**, you need to open the file with a Windows browser:

```bash
explorer.exe `wslpath -w $PWD/book/html/index.html`
```

You can now view **index.html** directly in your browser.
