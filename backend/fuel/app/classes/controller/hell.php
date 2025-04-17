<?php

class Controller_Hell extends Controller_Template
{

	public function action_world()
	{
		$data["subnav"] = array('world'=> 'active' );
		$this->template->title = 'Hell &raquo; World';
		$this->template->content = View::forge('hell/world', $data);
	}

}
