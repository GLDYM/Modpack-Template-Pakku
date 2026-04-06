# Modpack Template - Pakku

A Minecraft Modpack Template based on [Pakku](https://github.com/juraj-hrivnak/Pakku), providing CI/CD of modpack.

## Feature

- Auto validate json & toml files
- Auto build client-pack & server-pack
- Auto test client-pack & server-pack
- Auto test the connection between client and server
- Provide lightweight server-pack by distributing the source

## Usage

### Pakku

See [https://juraj-hrivnak.github.io/Pakku/home.html](https://juraj-hrivnak.github.io/Pakku/home.html).

### Github Action

#### Auto build

- The github action will be triggered when changing the content of modpack, including `pakku.json`, `pakku-lock.json` or `.pakku/`.
- The action will validate json & toml files in `.pakku/`, you can configure in `exclude.txt` to exclude some files.
- Then build client-pack, server-pack & full server-pack, release them under `build` tag.
- Finally start up client-pack & server-pack to test.

#### Release & publish

- You need to manually trigger the release script in Github Action Page.
- The action will parse the version of modpack and create a new release.
- If you want to auto publish your modpack to platforms like Curseforge or Modrinth, refer [Kir-Antipov/mc-publish](https://github.com/marketplace/actions/mc-publish) to change the release script.

## License

MIT License

## Special Thanks

- [Pakku](https://github.com/juraj-hrivnak/Pakku)
- [PortableMC](https://github.com/theorzr/portablemc)