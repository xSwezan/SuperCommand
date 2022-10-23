return function(Name: string, Value: any)
	return {
		type = "SetVariable";
		payload = {Name, Value};
	}
end