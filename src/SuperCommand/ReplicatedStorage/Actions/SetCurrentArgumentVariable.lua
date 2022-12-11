return function(Name: string, Value: any)
	return {
		type = "SetCurrentArgumentVariable";
		payload = {Name, Value};
	}
end