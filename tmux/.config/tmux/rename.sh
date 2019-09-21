
typeset -a gen_adjective=(admiring adoring affectionate agitated amazing angry awesome beautiful blissful bold boring brave busy \
                          charming clever cool compassionate competent condescending confident cranky crazy dazzling determined \
                          distracted dreamy eager ecstatic elastic elated elegant eloquent epic exciting fervent festive flamboyant \ 
                          focused friendly frosty funny gallant gifted goofy gracious great happy hardcore heuristic hopeful hungry \
                          infallible inspiring interesting intelligent jolly jovial keen kind laughing loving lucid magical mystifying \
                          modest musing naughty nervous nice nifty nostalgic objective optimistic peaceful pedantic pensive practical \
                          priceless quirky quizzical recursing relaxed reverent romantic sad serene sharp silly sleepy stoic strange \
                          stupefied suspicious sweet tender thirsty trusting unruffled upbeat vibrant vigilant vigorous wizardly \
                          wonderful xenodochial youthful zealous zen)

typeset -a gen_name=(albattani allen almeida antonelli agnesi archimedes ardinghelli aryabhata austin babbage banach banzai bardeen bartik \
                     bassi beaver bell benz bhabha bhaskara black blackburn blackwell bohr booth borg bose bouman boyd brahmagupta brattain \
                     brown buck burnell cannon carson cartwright cerf chandrasekhar chaplygin chatelet chatterjee chebyshev cohen chaum clarke \
                     colden cori cray curran curie darwin davinci dewdney dhawan diffie dijkstra dirac driscoll dubinsky easley edison einstein \
                     elbakyan elgamal elion ellis engelbart euclid euler faraday feistel fermat fermi feynman franklin gagarin galileo galois \
                     ganguly gates gauss germain goldberg goldstine goldwasser golick goodall gould greider grothendieck haibt hamilton haslett \
                     hawking hellman heisenberg hermann herschel hertz heyrovsky hodgkin hofstadter hoover hopper hugle hypatia ishizaka jackson \
                     jang jennings jepsen johnson joliot jones kalam kapitsa kare keldysh keller kepler khayyam khorana kilby kirch knuth kowalevski \
                     lalande lamarr lamport leakey leavitt lederberg lehmann lewin lichterman liskov lovelace lumiere mahavira margulis matsumoto \
                     maxwell mayer mccarthy mcclintock mclaren mclean mcnulty mendel mendeleev meitner meninsky merkle mestorf minsky mirzakhani \
                     moore morse murdock moser napier nash neumann newton nightingale nobel noether northcutt noyce panini pare pascal pasteur \
                     payne perlman pike poincare poitras proskuriakova ptolemy raman ramanujan ride montalcini ritchie rhodes robinson roentgen \
                     rosalind rubin saha sammet sanderson satoshi shamir shannon shaw shirley shockley shtern sinoussi snyder solomon spence \
                     stallman stonebraker sutherland swanson swartz swirles taussig tereshkova tesla tharp thompson torvalds tu turing \
                     varahamihira vaughan visvesvaraya volhard villani wescoff wilbur wiles williams williamson wilson wing wozniak wright \
                     wu yalow yonath zhukovsky)


function random_name {
    local adjective=$(( $RANDOM % ${#gen_adjective[@]} + 1 ))
    local name=$(( $RANDOM % ${#gen_name[@]} + 1 ))
    echo "${gen_adjective[$adjective]}-${gen_name[$name]}"
}

hook=${1} session=${2} window=${3} name=$(random_name)

case ${hook} in
    after-new-session)
        # if [[ ! -z "${session##*[!0-9]*}" ]] {
        #     tmux rename-session -t "${session}" "${name}"
        # }
        tmux rename-window -t "${session}" "${name}"
    ;;
    after-new-window) 
        tmux rename-window -t "${session}:${window}" "${name}" 
    ;;
    *) 
        echo "hook: ${hook}"
        echo "session: ${session}"
        echo "window: ${window}"
        echo "result: ${name}" 
    ;;
esac
