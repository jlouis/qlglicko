#!/bin/sh

update_core () {
	cd deps/qlglicko_core && git pull && cd ../..
}

update_web () {
	cd deps_qlglicko_web && git pull && cd ../..
}

compile () {
	rebar compile
}

push () {
	make push
}

update_core
update_web
compile
push
