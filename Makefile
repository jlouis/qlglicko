PROJECT = qlglicko
.DEFAULT_GOAL = deps

.PHONY: release clean-release push

push:
	rsync -ar rel/qlglicko myrddraal:P/qlglicko/rel

##### ----------------------------------------------------------------------

postgres_dump:
	pg_dump -Fc qlglicko > qlglicko.dump

postgres_restore:
	dropdb qlglicko
	pg_restore -e -C -d postgres ./qlglicko.dump

console:
	_rel/qlglicko/bin/qlglicko console \
		-pa ../../deps/*/ebin

