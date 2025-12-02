from setuptools import setup, find_packages

setup(
    name='img-toolkit',
    version='1.0.0',
    description='Fast, private image compression and conversion tool for Debian/Ubuntu.',
    author='IT-BAER',
    author_email='',
    url='https://github.com/IT-BAER/IMG-Toolkit',
    packages=find_packages(),
    install_requires=[
        'Pillow>=9.0.0',
        'pyheif>=0.6.0',
        'pypdfium2>=4.30.0',
    ],
    entry_points={
        'console_scripts': [
            'img-toolkit=backend.image_converter.bootstraper:main',
        ],
    },
    classifiers=[
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.11',
        'Operating System :: POSIX :: Linux',
        'License :: OSI Approved :: MIT License',
    ],
    python_requires='>=3.9',
)
