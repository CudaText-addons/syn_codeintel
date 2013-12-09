<?php
include_once 'foo.class.php';

class bar extends foo{
	public function bye(){
		return ("Bye, {$this->name}\n");
	}
}

function bar_function(){
	phpinfo();

}

?>