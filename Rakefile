task :test do
	sh 'bash test/test.sh'
end

task :review_baseline_deltas do
  sh 'ksdiff test/baseline.diff test/computed.diff'
end

task :accept_baseline_deltas do
	sh 'mv test/computed.diff test/baseline.diff'
	git add test/baseline.diff
	git commit
end