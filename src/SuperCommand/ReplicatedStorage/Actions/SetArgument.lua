return function(Index: number, Value: any)
	return {
		type = "SetArgument";
		payload = {Index, Value};
	}
end