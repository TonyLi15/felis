# Papers

*Caracal: Contention Management with Deterministic Concurrency Control* - SOSP'21 [Paper](https://dl.acm.org/doi/10.1145/3477132.3483591) [Slides](https://docs.google.com/presentation/d/1yTEkQ7fRucArBguChkD3p_b6TOoqPdAK_rfSb7DBwog/edit?usp=sharing) [Talk](https://youtu.be/QZ8sMvck654) [Long Talk](https://youtu.be/NUWl4dSfA1c)

Build (Modified)
=====

1. First, run the configure script to download the build tool `buck` and generate local config file for it.

```
./configure
```

Note that the author's link for downloading `buck` is obsolete/invalid, and we replaced the valid link by retrieving `buck` from JitPack.

2. Now use `buck.pex` that downloaded from previous step to build.

The command

```
./build_buck.sh build db
```

will generate the debug binary to `buck-out/gen/db#debug`. 

If you need optimized build, you can run

```
./build_buck.sh build db_release
```

to generate the release binary to `buck-out/gen/db#release`.

Memo
===
Setup Java 8 (Buck's Requirement) for building
-----------------
1. Check the current Java version:
```
which java && java -version
```
2. If Java is newer version (most likely), then check if Java 8 is intalled on the environment:
```
apt list --installed | grep -i openjdk
```
3. Set `JAVA_HOME` and `PATH` to use Java 8
```
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
```

If missing files from submodules
-----------------
Initialize and Update submodules:
```
git submodule init && git submodule update
```
Verify whether debug or/and release binaries are built and executable
-----------------
```
find buck-out -name "db#{debug/release}" | cat
file buck-out/gen/db#debug buck-out/gen/db#release
```

Run
===

Setting Things Up
-----------------

Felis need to use HugePages for memory allocation (to reduce
the TLB misses). Common CSL cluster machines should have these already
setup, and you may skip this step.

The following command checks current system's HugePages configuration
```
cat /proc/sys/vm/nr_hugepages
```

The following pre-allocates 400GB
of HugePages. You can adjust the amount depending on your memory
size. (Each HugePage is 2MB by default in Linux.)

```
echo 204800 > /proc/sys/vm/nr_hugepages
```

Run the Controller
----------------

To run the workload, the felis-controller is needed. It is in a separate
git repository. Please check the README in felis-controller.

First, you need to enter the config for the nodes and controller, in
`config.json` in felis-controller.

Then, run the controller. We usually run the controller on localhost
when doing single-node experiments, and on a separate machine when
doing distributed experiments. It doesn't really matter though.

As long as the configuration doesn't change, you can let the controller
run all the time.

Start the database on each node
-------------------------------

Once the controller is initialized, on each node you can run:

```
buck-out/gen/db#release -c 127.0.0.1:<rpc_port> -n host1 -w tpcc -Xcpu16 -Xmem20G -XVHandleBatchAppend -XVHandleParallel
```

`-c` is the felis-controller IP address (<rpc_port> and <http_port>
below are specified in config.json as well), `-n` is the host name for
this node, and `-w` means the workload it will run (tpcc/ycsb).

`-X` are for the extended arguments. For a list of `-X`, please refer
to `opts.h`. Mostly you will need `-Xcpu` and `-Xmem` to specify how
many cores and how much memory to use. (Currently, number of CPU must
be multiple of 8. That's a bug, but we don't have time to fix it
though.)

Start running the workload
--------------------------

The node will initialize workload dataset and once they are idle, they
are waiting for further commands from the controller. When all of them
finish initialization, you can tell the controller that everybody can
proceed:

```
curl localhost:<http_port>/broadcast/ -d '{"type": "status_change", "status": "connecting"}'
```

Upon receiving this, the controller would broadcast to every node to
start running the benchmark. When it all finishes, you can also use the
following commands to safely shutdown. (Optional)

```
curl localhost:<http_port>/broadcast/ -d '{"type": "status_change", "status": "exiting"}'
```

Logs
----

If you are running the debug version, the logging level is "debug" by
default, otherwise, the logging level is "info". You can always tune
the debugging level by setting the `LOGGER` environmental
variable. Possible values for `LOGGER` are: `trace`, `debug`, `info`,
`warning`, `error`, `critical`, `off`.

The debug level will output to a log file named `dbg-hostname.log`
where hostname is your node name. This is to prevent debugging log
flooding your screen.


Development
===========

ccls language server
--------------------

We use `ccls` <https://github.com/MaskRay/ccls> to help our development.
ccls is a C/C++/ObjC language server supporting cross references,
hierarchies, completion and semantic highlighting. It is *not* essential
for running the experiment.

If you have run the `./configure` script, it would generate a `.ccls`
configuration file for you. `ccls` supports
[Emacs](https://github.com/MaskRay/ccls/wiki/lsp-mode),
[Vim](https://github.com/MaskRay/ccls/wiki/vim-lsp) and
[VSCode](https://github.com/MaskRay/ccls/wiki/Visual-Studio-Code).

Mike has a precompiled `ccls` binary on the cluster machine. You can
download at <http://fs.csl.utoronto.ca/~mike/ccls>.

Zhiqi has some experience with using ccls with VSCode.


Test
----

FIXME: Unit tests are broken now. You may skip this section.

Use

```
./buck build test
```

to build the test binary. Then run the `buck-out/gen/dbtest` to run
all unit tests. We use google-test. To run partial test, please look
at
https://github.com/google/googletest/blob/master/googletest/docs/advanced.md#running-a-subset-of-the-tests
.
