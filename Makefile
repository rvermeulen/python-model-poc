PYTHON_QL_PACK_VERSION = 0.9.13
PYTHON_ALL_PACK_VERSION = 0.11.13
PYTHON_QL_PACK_PATH = $(HOME)/.codeql/packages/codeql/python-queries/$(PYTHON_QL_PACK_VERSION)

all: python.sarif

python-db: example/test.py
	codeql database create --overwrite --language=python --source-root=example $@

$(PYTHON_QL_PACK_PATH)/.codeql/libraries/codeql/python-all/$(PYTHON_ALL_PACK_VERSION)/semmle/python/frameworks/data/ModelsAsData.qll:
	codeql pack download codeql/python-queries@$(PYTHON_QL_PACK_VERSION)

$(PYTHON_QL_PACK_PATH)/.codeql/libraries/codeql/python-all/$(PYTHON_ALL_PACK_VERSION)/semmle/python/frameworks/data/ModelsAsData.qll.bak: $(PYTHON_QL_PACK_PATH)/.codeql/libraries/codeql/python-all/$(PYTHON_ALL_PACK_VERSION)/semmle/python/frameworks/data/ModelsAsData.qll
	sed -i.bak 's/extends RemoteFlowSource/extends RemoteFlowSource::Range/' $(PYTHON_QL_PACK_PATH)/.codeql/libraries/codeql/python-all/$(PYTHON_ALL_PACK_VERSION)/semmle/python/frameworks/data/ModelsAsData.qll
	touch $@

$(PYTHON_QL_PACK_PATH)/Security/CWE-089/SqlInjection.qlx: $(PYTHON_QL_PACK_PATH)/.codeql/libraries/codeql/python-all/$(PYTHON_ALL_PACK_VERSION)/semmle/python/frameworks/data/ModelsAsData.qll.bak
	codeql query compile --precompile $(PYTHON_QL_PACK_PATH)/Security/CWE-089/SqlInjection.ql

python.sarif: python-db python-models/remote.yml $(PYTHON_QL_PACK_PATH)/.codeql/libraries/codeql/python-all/$(PYTHON_ALL_PACK_VERSION)/semmle/python/frameworks/data/ModelsAsData.qll.bak $(PYTHON_QL_PACK_PATH)/Security/CWE-089/SqlInjection.qlx
	codeql database analyze --model-packs advanced-security/python-models@0.0.1 --rerun --format=sarif-latest -o $@ --sarif-add-file-contents --additional-packs=python-models -- python-db codeql/python-queries@$(PYTHON_QL_PACK_VERSION):Security/CWE-089/SqlInjection.ql 

.PHONY: clean
clean:
	rm -f python.sarif
	rm -rf python-db
	rm -rf $(PYTHON_QL_PACK_PATH) 