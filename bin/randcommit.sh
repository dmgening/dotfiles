#!/bin/sh

curl -s 'http://whatthecommit.com/' | grep '<p>' | cut -c4-