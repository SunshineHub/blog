var exec = require('child_process').exec;
var gulp = require('gulp');
gulp.task('hexo', function(cb){
  exec('hexo clean && hexo g', function(err){
	if(err) return cb(err);
	cb();
  });	
});

gulp.task('default',['hexo']);