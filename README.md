# promtool-action
![GitHub Actions Logo](./img/github_actions_logo.png)  ![Prometheus Logo](./img/prometheus_logo.png)

Github action to check whether a prometheus config/rule file is syntactically correct without starting a Prometheus server.
 
The output of the actions can be viewed from the Actions tab in the main repository view. If the actions are executed on a pull request event, a comment may be posted on the pull request.

Promtool Action is a single GitHub Action that can be executed on different files(config/rules) depending on the content of the GitHub Actions YAML file.

## Success Criteria
An exit code of `0` is considered a successful execution.

## Usage
The most common usage is to run `promtool check <config|rules>` on prometheus config/rules files. A comment will be posted to the pull request depending on the output of the Promtool check command being executed. This workflow can be configured by adding the following content to the GitHub Actions workflow YAML file.
```yaml
name: 'Promtool Check Action'
on:
  pull_request:
    branches:
      - master
    paths:
      - 'prometheus/rules/*.yml'
jobs:
  promtool:
    name: 'Promtool'
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest]
      fail-fast: true
    steps:
      - name: 'Checkout'
        uses: actions/checkout@master
      - name: 'Promtool Check'
        uses: karancode/promtool-action@v0.0.1
        with:
          prom_version: '2.9.2'
          prom_check_subcommand: 'rules'
          prom_check_files: './prometheus/rules/*.yml'
          prom_comment: true
        env:
          GITHUB_ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```
This was a simplified example showing the basic features of this Promtool GitHub Actions. More examples, coming soon!

# Inputs

Inputs for Promtool GitHub Actions to perform check action.

* `prom_version` - (Optional) The Prometheus version to use for `promtool check`. Defaults to v`2.16.0`.
* `prom_check_subcommand` - (Required) The subcommand for promtool check. Currently supported are `config` & `rules`.
* `prom_check_files` - (Required) The promtheus config/rules files(s) path to be checked. Make sure set config file path when subcommand is `config` and rules file path when subcommand is `rules`. If there are multiple files, you can either specify regex or set space separated file paths.
* `prom_comment` - (Optiona) Whether or not to comment on GitHub pull requests. Defaults to `false`.


## Outputs

Outputs are used to pass information to subsequent GitHub Actions steps.

* `promtool_output` - The promtool check <config|rules> outputs.

## Secrets

Secrets are similar to inputs except that they are encrypted and only used by GitHub Actions. It's a convenient way to keep sensitive data out of the GitHub Actions workflow YAML file.

* `GITHUB_ACCESS_TOKEN` - (Optional) The GitHub API token used to post comments to pull requests. Not required if the `prom_comment` input is set to `false`.
