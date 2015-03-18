#!/bin/bash

# Kick off the puppet runs, control is first for databases and api
vagrant ssh control -c "sudo puppet agent -t"
