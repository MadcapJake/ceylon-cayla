import ceylon.language.meta.declaration { ClassDeclaration, FunctionOrValueDeclaration, ValueDeclaration, OpenType }
import io.cayla.web { Route, Handler, Get, Put, Post, Trace, Head, Delete, Options, Connect,
  Blocking }
import ceylon.language.meta { annotations, type }
import ceylon.collection { HashMap }
import io.cayla.web.descriptor { unmarshallers }

"""Describes an handler."""
shared class HandlerDescriptor(
    Anything(Anything[]) factory,
    shared ClassDeclaration classDecl,
    "Returns the [[Route]] of this handler, it may be null"
    shared {Route+}? route) {
	
	// Checks
	for (FunctionOrValueDeclaration parameterDecl in classDecl.parameterDeclarations) {
		// Must be shared
		if (!parameterDecl.shared) {
			throw Exception("Parameter ``parameterDecl.name`` of ``classDecl`` must be shared");
		}
		// Must be unshmarshallable
		if (!unmarshallers.find(parameterDecl.openType) exists) {
			throw Exception("Type ``parameterDecl.openType`` of parameter ``parameterDecl.name`` of ``classDecl`` is not yet supported");
		}
	}

	shared Boolean blocking = annotations(`Blocking`, classDecl) exists;
	
	// Methods or empty (i.e all)
	{String*} m0 = annotations(`Get`, classDecl) exists then {"GET"} else {};
	{String*} m1 = annotations(`Put`, classDecl) exists then {"PUT",*m0} else {*m0};
	{String*} m2 = annotations(`Post`, classDecl) exists then {"POST",*m1} else {*m1};
	{String*} m3 = annotations(`Trace`, classDecl) exists then {"TRACE",*m2} else {*m2};
	{String*} m4 = annotations(`Head`, classDecl) exists then {"HEAD",*m3} else {*m3};
	{String*} m5 = annotations(`Delete`, classDecl) exists then {"DELETE",*m4} else {*m4};
	{String*} m6 = annotations(`Options`, classDecl) exists then {"OPTIONS",*m5} else {*m5};
	{String*} m7 = annotations(`Connect`, classDecl) exists then {"CONNECT",*m6} else {*m6};
	shared {String*} methods = m7;
	
	// Helper for below
	Anything defaultOf(OpenType type) {
		Unmarshaller<Anything>? unmarshaller = unmarshallers.find(type);
		if (exists unmarshaller) {
			return unmarshaller.default;
		} else {
			throw Exception("Unsupported parameter type ``type``");
		}
	}
	
	// Determine default parameters using the minimal constructor we can find
	// and then reading the values
	Anything min = factory([
			for (FunctionOrValueDeclaration parameterDecl in classDecl.parameterDeclarations)
				if (!parameterDecl.defaulted)
					defaultOf(parameterDecl.openType)
	]);
	assert(is Object min);
	value defaultParameters = HashMap {
		for (FunctionOrValueDeclaration parameterDecl in classDecl.parameterDeclarations)
			if (is ValueDeclaration parameterDecl, parameterDecl.defaulted)
				if (is Object aaa = parameterDecl.memberGet(min))
					parameterDecl.name->aaa
    };
	
	// Methods
	
	
	"Instantiate an handler"
	throws(`class Exception`, "when the handler cannot be instantiated")
	shared Handler instantiate("The arguments" <String->String>* arguments) {
		Anything[] buildArguments(FunctionOrValueDeclaration[] parametersDecl) {
			FunctionOrValueDeclaration? parameterDecl = parametersDecl.first;
			if (is ValueDeclaration parameterDecl) {
				Anything[] rest = buildArguments(parametersDecl.rest);
				OpenType type = parameterDecl.openType;
				String name = parameterDecl.name;
				<String->String>? argument = arguments.find((String->String elem) => elem.key.equals(name));
				Unmarshaller<Anything>? unmarshaller = unmarshallers.find(type);
				if (exists unmarshaller) {
					String? item = argument?.item;
					if (!(item exists) && parameterDecl.defaulted) {
						Object? default = defaultParameters[parameterDecl.name];
						return [default,*rest];
					} else {
						Anything unmarshalled = unmarshaller.unmarshall(item);
						return [unmarshalled,*rest];
					}
				} else {
					throw Exception("Unsupported parameter type ``type``");
				}
			} else {
				return [];
			}
		}
		Anything instance = factory(buildArguments(classDecl.parameterDeclarations));
		assert(is Handler instance);
		return instance;
	}
	
	"Extract the request parameters of a handler"
	shared Map<String, String> parameters("The handler to examine" Handler handler) => 
		HashMap {
			for (FunctionOrValueDeclaration parameterDecl in classDecl.parameterDeclarations)
				if (is ValueDeclaration parameterDecl, exists t = parameterDecl.memberGet(handler))
					parameterDecl.name->t.string
		};
	
	
	"Test if the specified handler is described by this descriptor instance"
	shared Boolean isInstance("The handler to test" Handler handler) => type(handler).declaration.equals(classDecl);

  shared actual String string {
    if (exists route) {
      return "HandlerDescriptor[class=``classDecl.qualifiedName``,route=``route``]";
    } else {
      return "HandlerDescriptor[class=``classDecl.qualifiedName``]";
    }
  }
}