# Class: 继承


class Animal:
    sound = "generic"

    @classmethod
    def make_sound(cls):
        return cls.sound

    @staticmethod
    def info():
        return "I am an animal"


class Dog(Animal):
    sound = "woof"

    @staticmethod
    def info():
        return "I am a dog"


class Cat(Animal):
    sound = "meow"


print("Animal sound:", Animal.make_sound())  # generic
print("Dog sound:", Dog.make_sound())  # woof
print("Cat sound:", Cat.make_sound())  # meow

# staticmethod 也可以被子类 override
print("Animal info:", Animal.info())  # I am an animal
print("Dog info:", Dog.info())  # I am a dog
print("Cat info:", Cat.info())  # I am an animal (继承)
