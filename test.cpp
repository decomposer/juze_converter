#define FOO BAR

class FooTester
{
public:
    void foo() {}
    void fooo() {}
    void fooTest() {}
    void testBar() {}
    void testFooBar() {}
    void foo_bar() {}
    void test_foo_bar() {}
};

int main()
{
    FooTester foo;
    foo.foo();
    foo.fooTest();
    foo.testBar();
    foo.testFooBar();
    foo.foo_bar();
    foo.test_foo_bar();
    return 0;
}
