local Types = {}

export type CommandArgument = {
	Name: string;
	Type: string;
}

export type Command = {
	Name: string;
	Description: string;
	Arguments: {CommandArgument};
};

export type Type = {
	Name: string;

	Get: (string) -> any;
}

return Types