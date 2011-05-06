all: description_lines.png description_matrix.png description_process.png

description_lines.png: description_lines.dot
	dot -Tpng -o"$@"_ $<
	pngcrush "$@"_ $@
	rm -f "$@"_

description_matrix.png: description_matrix.dot
	dot -Tpng -o"$@"_ $<
	pngcrush "$@"_ $@
	rm -f "$@"_

description_process.png: description_process.dot
	dot -Tpng -o"$@"_ $<
	pngcrush "$@"_ $@
	rm -f "$@"_
