import ceylon.test { test, assertEquals }
import ceylon.language.meta.declaration { Package }
import cayla.descriptor { ApplicationDescriptor, ControllerDescriptor }
import test.cayla.descriptor.application.support.app001 { controller001=mycontroller }
import test.cayla.descriptor.application.support.app002 { controller002=mycontroller }

shared test void test001() {
	Package pkg = `package test.cayla.descriptor.application.support.app001`;
	ApplicationDescriptor desc = ApplicationDescriptor(pkg);
	assertEquals(1, desc.controllers.size);
	ControllerDescriptor? controller = desc.controllers[0];
	assert(exists controller);
	assertEquals(controller001, controller.controller);
}

shared test void test002() {
	Package pkg = `package test.cayla.descriptor.application.support.app002`;
	ApplicationDescriptor desc = ApplicationDescriptor(pkg);
	value match = desc.resolve("/foo_value/bar");
	assert(exists match);
	assertEquals(LazyMap({"foo"->"foo_value"}), match.params);
	value handler = match.target.instantiate(*match.params);
	assert(exists index = controller002.isInstance(handler));
	assertEquals("foo_value", index.foo);
	assertEquals("default_bar", index.bar);
}