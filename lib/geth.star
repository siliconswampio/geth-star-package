# Imports
geth = import_module("github.com/kurtosis-tech/eth-network-package/src/el/geth/geth_launcher.star")
genesis_constants = import_module("github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star")
genesis_data_generator = import_module("github.com/kurtosis-tech/eth-network-package/src/prelaunch_data_generator/el_genesis/el_genesis_data_generator.star")
static_files = import_module("github.com/kurtosis-tech/eth-network-package/static_files/static_files.star")
input_parser = import_module("github.com/kurtosis-tech/eth-network-package/package_io/input_parser.star")

# Constants
CLIENT_SERVICE_NAME_PREFIX = "el-client-"
CLIENT_LOG_LEVEL = "3"
CLIENT_IMAGE = input_parser.DEFAULT_EL_IMAGES["geth"]
GLOBAL_LOG_LEVEL = ""

GENESIS_DATA_GENERATION_TIME = 5 * time.second
NODE_STARTUP_TIME = 5 * time.second


def run(plan, network_params, el_genesis_data):
    geth_prefunded_keys_artifact_name = plan.upload_files(
        static_files.GETH_PREFUNDED_KEYS_DIRPATH,
        name="geth-prefunded-keys",
    )
    launcher = geth.new_geth_launcher(
        network_params["network_id"],
        el_genesis_data,
        geth_prefunded_keys_artifact_name,
        genesis_constants.PRE_FUNDED_ACCOUNTS
    )
    service_name = "{0}{1}".format(CLIENT_SERVICE_NAME_PREFIX, 0)
    return geth.launch(
        plan,
        launcher,
        service_name,
        CLIENT_IMAGE,
        CLIENT_LOG_LEVEL,
        GLOBAL_LOG_LEVEL,
        # If empty, the node will be launched as a bootnode
        [],  # existing_el_clients
        [],  # extra_params
    )

def generate_el_genesis_data(plan, final_genesis_timestamp, network_params):
    el_genesis_generation_config_template = read_file(static_files.EL_GENESIS_GENERATION_CONFIG_TEMPLATE_FILEPATH)
    el_genesis_data = genesis_data_generator.generate_el_genesis_data(
        plan,
        el_genesis_generation_config_template,
        final_genesis_timestamp,
        network_params["network_id"],
        network_params["deposit_contract_address"],
        network_params["genesis_delay"],
        network_params["capella_fork_epoch"],
    )
    return el_genesis_data

def generate_genesis_timestamp(num_participants = 1):
    return (time.now() + GENESIS_DATA_GENERATION_TIME + num_participants * NODE_STARTUP_TIME).unix
