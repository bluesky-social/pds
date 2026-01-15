# Publishing a new version of the PDS distro

Below are the steps to publish a new version of the PDS distribution.  The distribution is hosted by GitHub Container Registry, supported by the `build-and-push-ghcr` workflow.  We use git tags to generate Docker tags on the resulting images.

1. Update the @atproto/pds dependency in the `service/` directory.

    We're using version `0.4.999` as an example.  The latest version of the [`@atproto/pds` package](https://www.npmjs.com/package/@atproto/pds) must already be published on npm.
    ```sh
    $ cd service/
    $ pnpm update @atproto/pds@0.4.999
    $ cd ..
    ```

2. Commit the change directly to `main`.

    As soon as this is committed and pushed, the workflow to build the Docker image will start running.
    ```sh
    $ git add service/
    $ git commit -m "pds v0.4.999"
    $ git push
    ```

3. Smoke test the new Docker image.

    The new Docker image built by GitHub can be found [here](https://github.com/bluesky-social/pds/pkgs/container/pds).  You can use the `sha-`prefixed tag to deploy this image to a test PDS for smoke testing.

4. Finally, tag the latest Docker image version.

    The Docker image will be tagged as `latest`, `0.4.999`, and `0.4`.  Our self-hosters generally use the `0.4` tag, and their PDS distribution will be updated automatically over night in many cases.  The Docker tags are generated automatically from git tags.
    ```sh
    $ git tag v0.4.999
    $ git push --tags
    ```
