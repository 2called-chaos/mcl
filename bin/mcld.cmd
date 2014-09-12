@ECHO OFF
cd %~dp0/..
bundle exec ruby lib/mcld.rb %*
