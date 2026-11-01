"""Offline, stdlib-only extraction checks. Does not import or run upstream code."""
import ast
import hashlib
import json
from pathlib import Path
import types
import unittest

ROOT = Path(__file__).resolve().parents[3]
VENDOR = ROOT / 'tools/vendor/autopilot-godot'
MODIFIED = {'autopilot/engines/__init__.py'}


class ExtractionTests(unittest.TestCase):
    def test_provenance_and_original_bytes(self):
        manifest = json.loads((VENDOR / 'UPSTREAM.json').read_text(encoding='utf-8'))
        self.assertEqual(manifest['commit'], '48966d174939487cc759fdf8560f2bed6e717676')
        for rel, digest in manifest['upstream_sha256'].items():
            path = VENDOR / rel
            self.assertTrue(path.is_file(), rel)
            if rel not in MODIFIED:
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), digest, rel)

    def test_python_syntax(self):
        for path in VENDOR.rglob('*.py'):
            ast.parse(path.read_text(encoding='utf-8'), filename=str(path))

    def test_no_other_engine_plugins_or_adapters(self):
        for engine in ('unity', 'unreal'):
            self.assertFalse((VENDOR / 'plugin' / engine).exists())
            self.assertFalse((VENDOR / 'autopilot/engines' / (engine + '.py')).exists())

    def test_licenses_and_script_dependencies(self):
        self.assertIn('Apache License', (VENDOR / 'LICENSE').read_text())
        addon = VENDOR / 'plugin/godot/addons/autopilot'
        self.assertEqual(len(list((addon / 'fonts').glob('OFL-*.txt'))), 3)
        import re
        for script in addon.rglob('*.gd'):
            for rel in re.findall(r'preload\("([^"]+)"\)', script.read_text(encoding='utf-8')):
                path = addon.parents[1] / rel[6:] if rel.startswith('res://') else script.parent / rel
                self.assertTrue(path.is_file(), f'{script.name}: {rel}')

    def test_registry_contract_without_importing_service(self):
        # Test only registry logic with explicit stand-ins, NOT engine or service integration.
        tree = ast.parse((VENDOR / 'autopilot/engines/__init__.py').read_text(encoding='utf-8'))
        tree.body = [n for n in tree.body if not isinstance(n, ast.ImportFrom)]
        class Engine:
            pass
        class Godot(Engine):
            name = 'godot'
            def project_at(self, path):
                return path if (Path(path) / 'project.godot').is_file() else None
        ns = {'Engine': Engine, 'Godot': Godot, 'OpEngine': Engine}
        exec(compile(tree, '<registry-contract>', 'exec'), ns)
        self.assertEqual(ns['get']().name, 'godot')
        self.assertEqual(ns['get'](' GODOT ').name, 'godot')
        for name in ('unreal', 'unity', 'unknown'):
            with self.assertRaises(ValueError):
                ns['get'](name)
        with self.assertRaises(ValueError):
            ns['for_hello']({'engine': 'unreal'})
        self.assertEqual(ns['find_project'](str(VENDOR / 'plugin/godot/tests/game'))[0].name, 'godot')
        self.assertEqual(ns['find_project']('/missing-project'), (None, None))


if __name__ == '__main__':
    unittest.main()
