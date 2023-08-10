#!/bin/bash

usermod -u "$USER_ID" www-data
groupmod -g "$GROUP_ID" www-data
usermod -d /var/www/ www-data
