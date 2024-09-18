# Setup Maven Action

This is composite action which help to prepare GitHub Actions environment for Maven build by calling:

- [actions/setup-java](https://github.com/marketplace/actions/setup-java-jdk)
- [actions/cache](https://github.com/marketplace/actions/cache)
- [stCarolas/setup-maven](https://github.com/marketplace/actions/setup-maven)
- [s4u/maven-settings-action](https://github.com/marketplace/actions/maven-settings-action)

:exclamation: You **should not** include above actions in your configuration - in other case  those will be **called twice**. :exclamation:

For default values you only need:

```yml
    steps:

      - name: Setup Maven Action
        uses: emergentdotorg/github-actions/maven-release@main

      - run: mvn -V ...
```

# Params mapping for sub actions

## setup-java

| params            | destination  | default |
|-------------------|--------------|---------|
| java-version      | java-version | 17      |
| java-distribution | distribution | zulu    |

## cache

A cache action is configured as:

```yaml
    - uses: actions/cache
      with:
        path: |
          ${{ inputs.cache-path }}
          ${{ inputs.cache-path-add }}
        key: ${{ inputs.cache-prefix }}${{ runner.os }}-jdk${{ inputs.java-version }}-${{ inputs.java-distribution }}-maven${{ inputs.maven-version }}-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ inputs.cache-prefix }}${{ runner.os }}-jdk${{ inputs.java-version }}-${{ inputs.java-distribution }}-maven${{ inputs.maven-version }}-
```

So we can use for action:

| params         | description                                              |
|----------------|----------------------------------------------------------|
| cache-enabled  | enable cache. Default true                               |
| cache-path     | default cache path for Maven with value ~/.m2/repository | 
| cache-path-add | additional value for cache path                          |
| cache-prefix   | prefix value for `key` and `restore-keys` cache params   |


## setup-maven

| params        | destination   | default |
|---------------|---------------|---------|
| maven-version | maven-version | 3.9.9   |

## maven-settings-action

| params                           | destination       |
|----------------------------------|-------------------|
| maven-settings-servers           | servers           |
| maven-settings-mirrors           | mirrors           |
| maven-settings-properties        | properties        |
| maven-settings-sonatypeSnapshots | sonatypeSnapshots |
| maven-settings-proxies           | proxies           |
| maven-settings-repositories      | repositories      |
