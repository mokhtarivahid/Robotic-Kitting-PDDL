#!/usr/bin/env python

from multiprocessing import Process, Queue, Manager
import subprocess, os, sys, time, re, signal
from collections import OrderedDict
import json

args_profiles = {
    'tfd'       : { 0 : 'y+Y+a+e+r+O+1+C+1+b+v+g', 
                    1 : 'y+Y+e+r+O+1+C+1+b+v' },
    'optic-clp' : { 0 : '',
                    1 : '-c -N',
                    2 : '-E -N' },
}

def kill_pid(pid):
    '''kill a subprocess by pid'''
    # first check if it is still running
    if pid == 0: return 0
    try:
        os.killpg(pid, 0)
    except OSError:
        return 0
    # kill if it is still running
    try:
        os.killpg(pid, signal.SIGTERM)
        # os.killpg(pid, signal.SIGKILL)
    except OSError:
        return 0
    return 0

def kill_jobs(pwd, planners):
    '''kill all subprocess by pid'''
    for planner in planners:
        pid_file = '%s/%s-pid.txt' % (pwd, planner)
        try:
            with open(pid_file, 'r+') as fp:
                pids = fp.readlines() 
                for pid in pids:
                    kill_pid(int(pid.strip()))
                fp.truncate(0)
        except:
            pass

###############################################################################
###############################################################################
def Plan(planners, domain, problem, wall_time, pwd, verbose=0):
    '''
    calls multiple planners to solve a given problem and as soon as 
    the first planner finds a plan, terminates all other planners and returns 
    '''
    try:
        # a shared dictionary to store all computed plans
        manager = Manager()
        collected_plans = manager.dict()

        # create a shared Queue to store the output planner
        returned_planner = Queue()

        # store the running processes
        process_lst = []

        # measure wall time
        t0 = time.time()

        # run in multiprocessing
        for pidx, planner in enumerate(planners):
            proc = Process(target=call_planner_mp, \
                args=(planner, domain, problem, args_profiles[planner][planners[planner]], collected_plans, returned_planner, pwd, verbose))
            proc.daemon = True
            process_lst.append(proc)
            proc.start()

        # stores already printed plans to do not print them again
        printed_plans = set()

        # wait until one process completes and returns or the computation time is over
        # while  time.time() - t0 < wall_time:
        while returned_planner.empty() and time.time() - t0 < wall_time:
            if verbose == 1:
                for cost, (planner, plan) in collected_plans.items():
                    if not cost in printed_plans:
                        printed_plans.add(cost)
                        print("\n; A plan found by '{}'".format(planner))
                        print_classical_plan(plan, cost)


        # kill running planners (subprocesses) if they are running
        kill_jobs(pwd, planners)

        # make sure processes terminate gracefully
        while process_lst:
            proc = process_lst.pop()
            while proc.is_alive():
                try:
                    proc.terminate()
                    proc.join()
                except: pass

        # return the best plan 
        if collected_plans:
            cost = min(collected_plans)
            planner, plan = collected_plans[cost]
            return planner, plan, cost

        return

    # make sure all processes are terminated when KeyboardInterrupt received
    except KeyboardInterrupt:
        if len(planners) > 1:
            kill_jobs(pwd, planners)
            print('ALL JOBS TERMINATED')
        raise


###############################################################################
###############################################################################
def call_planner_mp(planner, domain, problem, args, collected_plans, returned_planner, pwd, verbose):
    '''
    Call an external deterministic planner in multi processing.
    Arguments:
    @planner : the name of the external planner 
    @domain : path to a given domain 
    @problem : path to a given problem 
    @args : the default args of the external planner 
    @returned_planner : is a shared queue and stores the returned planner
    @pwd : the current working directory 
    @verbose : if True, prints statistics before returning
    '''
    def return_plan(planner):
        returned_planner.put(planner)
        return

    ## optic-clp planner ##
    if 'optic-clp' in planner.lower() or 'optic' in planner.lower():
        call_optic_clp(collected_plans, domain, problem, args, pwd, verbose)
        return_plan(planner)

    ## tfd planner ##
    elif 'tfd' in planner.lower():
        call_tfd(collected_plans, domain, problem, args, pwd, verbose)
        return_plan(planner)

    ## no planner ##
    else:
        print("\n[There is not yet a function for parsing the outputs of '{0}'!]\n".format(planner))
        return_plan(planner)

    return

###############################################################################
###############################################################################
## call optic-clp planner
def call_optic_clp(collected_plans, domain, problem, args='-b -N', pwd='/tmp', verbose=0):
    '''
    Call an external planner
    @domain : path to a given domain 
    @problem : path to a given problem 
    @verbose : if True, prints statistics before returning

    @return plan : the output plan is a list of actions as tuples, 
                   e.g., [[('move_to_grasp', 'arm1', 'box1', 'base1', 'box2'), ('move_to_grasp', 'arm2', 'box2', 'cap1', 'box1')], 
                          [('vacuum_object', 'arm2', 'cap1', 'box1'), ('vacuum_object', 'arm1', 'base1', 'box2')],
                          ...]
    '''

    # create the command
    cmd = 'timeout 1800 ./solvers/optic-clp {} {} {} & echo $! >> {}/optic-clp-pid.txt'.format(args, domain, problem, pwd)

    ## call command ##
    with open('/tmp/test.log', 'wb') as f:
        # store the planning output
        shell = ''
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, preexec_fn=os.setsid)
        for line in iter(process.stdout.readline, b''):
            # print out the planner's output
            if verbose == 2:
                sys.stdout.write(to_str(line))

            # store the planning output
            shell += to_str(line)

            # a plan is found 
            if 'All goal deadlines now no later than' in to_str(line):
                # extract plan cost
                cost = float(re.search(b'All goal deadlines now no later than (.*)', line).group(1).decode())

                ## refine the output screen and build a plan of actions' signatures ##
                # extract plan from '; Time' to the end of the string in shell
                shell = shell[shell.find('; Time'):].strip()

                # split shell into a list of actions
                shell = shell.split('\n')[1:-2]

                plan = OrderedDict()

                for action in shell:
                    action = re.split('[, ) (]+', action)
                    # { time : [(action, duration),...], ... }
                    plan.setdefault(action[0][:-1], []).append(tuple([action[1:-1],action[-1][1:-1]]))

                collected_plans[cost] = ('optic-clp', plan)
                shell = ''
            f.write(line)

    return 

###############################################################################
###############################################################################
## call temporal fast downward planner
def call_tfd(collected_plans, domain, problem, args='y+Y+a+e+r+O+1+C+1+b+v', pwd='/tmp', verbose=0):
    '''
    Call an external planner
    @domain : path to a given domain 
    @problem : path to a given problem 
    @verbose : if True, prints statistics before returning

    @return plan : the output plan is a list of actions as tuples, 
                   e.g., [[('move_to_grasp', 'arm1', 'box1', 'base1', 'box2'), ('move_to_grasp', 'arm2', 'box2', 'cap1', 'box1')], 
                          [('vacuum_object', 'arm2', 'cap1', 'box1'), ('vacuum_object', 'arm1', 'base1', 'box2')],
                          ...]
    '''

    # store the current directory
    cur_dir = os.getcwd()

    # change the path to the tfd planner's directory
    os.chdir('solvers/tfd-src-0.4/downward')

    # create the command
    cmd = "timeout 1800 python2 plan.py {} '{}' '{}' /tmp/plan.txt & echo $! >> {}/tfd-pid.txt".format(args, cur_dir+'/'+domain, cur_dir+'/'+problem, pwd)

    ## call command ##
    with open('/tmp/test.log', 'wb') as f:
        # store the planning output
        shell = ''
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, preexec_fn=os.setsid)
        for line in iter(process.stdout.readline, b''):
            # print out the planner's output
            if verbose == 2:
                sys.stdout.write(to_str(line))

            # store the planning output
            shell += to_str(line)

            # a plan is found 
            if 'Solution with original makespan' in to_str(line):
                # extract plan cost
                cost = float(re.search(b'makespan (.*) found', line).group(1).decode())

                ## refine the output screen and build a plan of actions' signatures ##
                # extract plan from '; Time' to the end of the string in shell
                shell = shell[shell.find('Found new plan:'):].strip()

                # split shell into a list of actions
                shell = shell.split('\n')[1:-1]

                plan = OrderedDict()

                for action in shell:
                    action = re.split('[, ) (]+', action)
                    # { time : [(action, duration),...], ... }
                    plan.setdefault(action[0][:-1], []).append(tuple([action[1:-1],action[-1][1:-1]]))

                collected_plans[cost] = ('tfd', plan)
                shell = ''
            f.write(line)

    # change path back to the current directory
    os.chdir(cur_dir)

    return 

###############################################################################
###############################################################################
## checks the output type and convert it to str
## in python 3 is of type 'byte' and in 2 is of type 'str' already
def to_str(output):

    if output is None: return str()

    ## bytes to string (Python 3) ##
    if sys.version_info[0] > 2:
        return ''.join(map(chr, output))

    ## already in string ##
    return str(output)


###############################################################################
###############################################################################
## print out a plan in a classical readable format
def print_classical_plan(plan, cost=None):
    '''print out given plan in a readable format'''
    if plan is None: return
    print("; Plan Metric: {}".format(cost))
    for step, actions in plan.items():
        print(step+' : '+' '.join([str('({}) [{}]'.format(' '.join(action),duration)) for action, duration in actions]))


###############################################################################
###############################################################################
## print out a plan in a classical readable format
def plan_to_file(path, plan, cost=None):
    '''print out given plan in a readable format'''
    if plan is None: return
    with open(path, 'w') as outfile:
        outfile.write("; Plan Metric: {}\n".format(cost))
        for step, actions in plan.items():
            outfile.write(step+' : '+' '.join([str('({}) [{}]\n'.format(' '.join(action),duration)) for action, duration in actions]))

    return

###############################################################################
###############################################################################
## store the plan in a json dictionary
def plan_to_json(problem, plan, cost=None):
    '''print out given plan in a readable format'''
    if plan is None: return
    plan_dict = OrderedDict()
    plan_dict['metric'] = cost
    plan_dict['steps'] = list(plan.keys())
    for step, actions in plan.items():
        plan_dict[float(step)] = list( \
            [{ "action" : action[0], "args" : action[1:], "duration" : float(duration) } for action, duration in actions])
    plan_json_str = json.dumps(plan_dict, indent=4)
    plan_json_file = '{}.plan.json'.format(os.path.splitext(problem)[0])
    with open(plan_json_file, 'w') as outfile:
        json.dump(json.loads(plan_json_str, object_pairs_hook=OrderedDict), outfile, sort_keys=False, indent=4)
    
    return plan_json_file


###############################################################################
## a test script to call planners' functions
## Note, only works on given classical/deterministic domains
###############################################################################

def parse():
    usage = 'python3 solver.py <DOMAIN> <PROBLEM> [-t <TIME>] [-v N] [-h]'
    description = "TEST THE EXTERNAL PLANNERS."
    parser = argparse.ArgumentParser(usage=usage, description=description)

    parser.add_argument('domain',  nargs='?', type=str, help='path to a PDDL domain file')
    parser.add_argument('problem', nargs='?', type=str, help='path to a PDDL problem file')
    parser.add_argument("-t", "--time", type=int, nargs='?', const=1, 
        help="limit for the computation time in seconds (default=60)", default=60)
    parser.add_argument("-p", "--plan",  type=str, help='output plan filename (default=/tmp/plan.txt)', 
        default="/tmp/plan.txt")
    parser.add_argument("-j", "--json", help="transform the output plan into a json file", 
        action="store_true")
    parser.add_argument("-v", "--verbose", default=1, type=int, choices=(0, 1, 2),
        help="increase output verbosity: 0 (minimal), 1 (high-level), 2 (classical planners outputs) (default=1)", )

    return parser

if __name__ == '__main__':

    import argparse

    parser = parse()
    args = parser.parse_args()

    if args.domain is None and args.problem is None:
        parser.print_help()
        exit()

    # store the list of external classical planners and assign a profile '0' to each one
    planners = { planner : 0 for planner in ['optic-clp','tfd'] }

    # store the computation time
    start = time.time()

    plan = Plan(planners, args.domain, args.problem, args.time, pwd = '/tmp/', verbose=args.verbose)

    if plan is not None:
        # print out the output plan
        print("\n; The best plan found by '%s' in %.2fs" % (plan[0], time.time() - start))
        print_classical_plan(plan[1], plan[2])

        # write out the output plan into a file
        plan_to_file(path=args.plan, plan=plan[1], cost=plan[2])
        print("\n; The plan '%s' was generated." % args.plan)

        # translate the output plan into a json format
        if args.json:
            plan_json_file = plan_to_json(problem=args.problem, plan=plan[1], cost=plan[2])
            print("\n; The plan '%s' in json format was generated." % plan_json_file)

    else:
        print("; No plan found in %.2fs" % (time.time() - start))
