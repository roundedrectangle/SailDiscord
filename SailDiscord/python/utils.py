import pyotherside
from typing import Callable # TODO: use collections.abc.Callable
import functools
import time

def exception_decorator(*exceptions: Exception):
    """Generates a decorator for handling exceptions in `exceptions`. Calls `pyotherside.send` on error. Preserves __doc__, __name__ and other attributes."""
    def decorator(func: Callable):
        @functools.wraps(func)
        def f(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except exceptions as e:
                pyotherside.send(f"An error occured while running function '{func.__name__}': {type(e).__name__}: {e}")

        return f
    return decorator


attributeerror_safe = exception_decorator(AttributeError)