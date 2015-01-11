PROJECT = qlglicko
.DEFAULT_GOAL = deps

.PHONY: release clean-release push

push:
	rsync -ar /home/jlouis/P/qlglicko /usr/jails/qlglicko/home/qlglicko/P

##### ----------------------------------------------------------------------

postgres_dump:
	pg_dump -Fc qlglicko > qlglicko.dump

postgres_restore:
	dropdb qlglicko
	pg_restore -e -C -d postgres ./qlglicko.dump

console:
	_rel/bin/qlglicko console \
		-pa ../deps/*/ebin

