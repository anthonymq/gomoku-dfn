PROVIDER ?= local
MODE ?= install
CANISTER_IDS:=.dfx/$(PROVIDER)/canister_ids.json
DFX_CFG:=dfx.json

PROJECT=gomoku
OBJ_DIR:=.dfx/$(PROVIDER)/canisters
CANISTER_TARGET:=$(OBJ_DIR)/$(PROJECT)/$(PROJECT).wasm


clean: 
	rm -rf .dfx/local/

clean-state:
	rm -rf .dfx/state

.PHONY: reinstall install install-canister install-assets

install: install-canister install-assets

install-assets: $(JS_TARGET) $(ASSETS_TARGET) $(DFX_CFG)
	dfx canister --network $(PROVIDER) install --mode $(MODE) $(PROJECT)_assets

install-canister: $(CANISTER_IDS) $(CANISTER_TARGET) $(DFX_CFG)
	dfx canister --network $(PROVIDER) install --mode $(MODE) $(PROJECT)

deploy:
	dfx build
	dfx canister install --all -m reinstall  

$(CANISTER_IDS): $(DFX_CFG)
	dfx canister --network $(PROVIDER) create --all

$(CANISTER_TARGET): $(CANISTER_IDS) $(MO_SRC) $(DFX_CFG)
	dfx build --network $(PROVIDER) --skip-frontend

$(ASSETS_TARGET) $(JS_TARGET) : $(CANISTER_IDS) $(MO_SRC) $(JS_SRC) $(JS_CFG) $(DFX_CFG) node_modules
	dfx build --network $(PROVIDER)