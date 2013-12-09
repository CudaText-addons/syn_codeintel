<?php
include "foo.class.php";
include "bar.class.php";


echo foo::hello_static("somename");
$foo_= new foo;
echo $foo_->hello(false,true);

$bar_=new bar;
echo $bar_->bye();

bar_function();

?>