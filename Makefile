k.PHONY: commit_build build show_pids console test kill_all release help

.DEFAULT_GOAL := build

show_pids:
	ps -ax | grep beam | grep cbs | awk '{print $$1 " " $$15}'

kill_all:
	killall -TERM beam.smp

all.clean:
	rm -rf _build/dev/rel

test:
	mix test

devrel:
	mix release --env=dev --verbose

console:
	iex --cookie cbs --name cbs@127.0.0.1 -S mix phx.server

commit_build:
	mix format --check-formatted
	mix clean
	mix compile --warnings-as-errors

build:
	mix format --check-formatted
	mix dialyzer --halt-exit-status
	mix clean
	mix compile --warnings-as-errors

release:
	mix docker.build
	mix docker.copy

help:
	cat Makefile | grep "^[A-z]" | awk '{print $$1}' | sed "s/://g"
