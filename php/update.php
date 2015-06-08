<?php

$response = array(
	'id' => file_get_contents('lastupdate.id')
);

echo json_encode($response);