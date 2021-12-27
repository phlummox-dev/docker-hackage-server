
# phlummox/hackage-server

[![build status](https://github.com/phlummox-dev/docker-hackage-server/actions/workflows/ci.yml/badge.svg)](https://github.com/phlummox-dev/docker-hackage-server/actions/workflows/ci.yml)

A Docker image for running an instance of [`hackage-server`][hackage-server] for
testing purposes. It includes an "admin" user (created with password "admin"),
that has been added to the "uploaders" group.

[hackage-server]: https://github.com/haskell/hackage-server

`hackage-server` is built from the [`hackage-deployment-2020-05-03`][hackage-deployment]
tag of the hackage-server Git repository.

[hackage-deployment]: https://github.com/haskell/hackage-server/commit/d43012169a11a0bb2229ef207e607b6c3d83b99c

The `hackage-server` documentation [claims][clean-exit] that the server
can be cleanly stopped using ctrl-c, but (since 2016, and as at December
2021) this doesn't always seem to be [the case][lockfile-bug].

[clean-exit]: https://github.com/haskell/hackage-server/blob/master/README.md#running
[lockfile-bug]: https://github.com/haskell/hackage-server/issues/548

