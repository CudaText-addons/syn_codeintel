<?php

class foo {
	protected $name;

	public function hello($name=FALSE,$backward=FALSE) {
		$name=$name?$name:$this->name;
		if ($backward) $name=$this->backward($name);

		return ("Hello, $name\n");
	}

	public function __construct($default_username="USERNAME"){
		$this->name=$default_username;
	}

	private function backward($word){
		$word=str_split($word);
		$tmp="";
		foreach ($word as $letter) {
			$tmp=$letter.$tmp;
		}
		return ($tmp);
	}

	protected function dummy(){
		return ("Does nothing\n");
	}

	static function hello_static($name){
		return ("Hello, $name\n");
	}

}

?>