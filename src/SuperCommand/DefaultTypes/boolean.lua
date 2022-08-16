return {
	Convert = function(Message: string)
		if not (Message) then return end
		
		if (Message:lower() == "true") then
			return true
		elseif (Message:lower() == "false") then
			return false
		end
	end;
	Get = function()
		return {true, false}
	end;
}