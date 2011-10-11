#!/bin/sh

for page in *.wiki; do
	./insert_page.sh $page
done
