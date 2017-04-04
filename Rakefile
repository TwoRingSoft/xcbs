task :test do
	sh 'test/test.sh'
end

task :accept_baseline_deltas do
	sh 'mv test/computed.diff test/baseline.diff'
	git add test/baseline.diff
	git commit
end