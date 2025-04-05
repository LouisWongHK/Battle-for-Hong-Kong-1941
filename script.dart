// Part 1: Initialization and Global Variables
const battlefield = document.getElementById('battlefield');
const supplyCount = document.getElementById('supply-count');
const waveNumber = document.getElementById('wave-number');
const enemiesRemainingDisplay = document.getElementById('enemies-remaining');
const startWaveBtn = document.getElementById('start-wave');
const gameOverDiv = document.getElementById('game-over');
const dragGhost = document.getElementById('drag-ghost');
const progressBar = document.getElementById('progress-bar');
let supplies = 50;
let selectedUnit = null;
let gameActive = false;
let waveCount = 0;
let score = 0;
let enemiesDefeated = 0;
let totalEnemiesInWave = 0;
let enemiesSpawned = 0;
let gameSpeed = 1;
let banzaiCount = 0;
const maxBanzai = 3;
let lastActivityTime = Date.now(); // Track last activity
let towerKills = new Map(); // Track kills per tower

// Part 2: Game Data (Units and Enemies)
const towers = {
    'royal-scots': { name: '2nd Royal Scots', cost: 10, damage: 5, range: 4, fireRate: 1000, sprite: 'https://i.imgur.com/rkEzkDE.png', ability: 'none' },
    'winnipeg-grenadiers': { name: 'Winnipeg Grenadiers', cost: 20, damage: 10, range: 4, fireRate: 1500, sprite: 'https://i.imgur.com/bR9vveb.png', ability: 'none' },
    'royal-rifles': { name: 'Royal Rifles', cost: 25, damage: 15, range: 5, fireRate: 1200, sprite: 'https://i.imgur.com/AM628F8.png', ability: 'boost' },
    'middlesex': { name: '1st Middlesex', cost: 30, damage: 8, range: 5, fireRate: 800, sprite: 'https://i.imgur.com/1iRftzs.png', ability: 'boost' },
    'rajputs': { name: '5/7th Rajputs', cost: 15, damage: 7, range: 3, fireRate: 1000, sprite: 'https://i.imgur.com/rkEzkDE.png', ability: 'melee' },
    'hkvdc': { name: 'HKVDC', cost: 5, damage: 3, range: 3, fireRate: 1000, sprite: 'https://i.imgur.com/dKsmPMp.png', ability: 'none' }
};

const enemies = [
    { type: '228th', name: '228th Regiment', health: 20, speed: 1, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 5, ability: 'none' },
    { type: '229th', name: '229th Regiment', health: 30, speed: 0.8, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 8, ability: 'none' },
    { type: '230th', name: '230th Regiment', health: 50, speed: 0.5, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 10, ability: 'none' },
    { type: 'artillery', name: '10th Artillery', health: 40, speed: 0.6, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 15, ability: 'splash' }
];

// Part 3: Battlefield Setup
function setupBattlefield() {
    for (let i = 0; i < 50; i++) {
        const cell = document.createElement('div');
        cell.classList.add('cell');
        cell.dataset.index = i;
        if (Math.random() < 0.2) cell.classList.add('fortified');
        cell.addEventListener('dragover', (e) => e.preventDefault());
        cell.addEventListener('dragenter', (e) => {
            if (!e.target.childElementCount) e.target.classList.add('drag-over');
        });
        cell.addEventListener('dragleave', (e) => e.target.classList.remove('drag-over'));
        cell.addEventListener('drop', placeTower);
        battlefield.appendChild(cell);
    }
}
setupBattlefield();

// Part 4: Drag-and-Drop and Click Functionality
document.querySelectorAll('.unit').forEach(unit => {
    unit.addEventListener('dragstart', (e) => {
        selectedUnit = unit.dataset.type;
        unit.classList.add('selected');
        const img = new Image();
        img.src = towers[selectedUnit].sprite;
        dragGhost.appendChild(img);
        e.dataTransfer.setDragImage(dragGhost, 16, 16);
        dragGhost.style.left = `${e.pageX - 16}px`;
        dragGhost.style.top = `${e.pageY - 16}px`;
        console.log('Dragging unit:', selectedUnit); // Debug
    });

    unit.addEventListener('dragend', () => {
        dragGhost.innerHTML = '';
        unit.classList.remove('selected');
        document.querySelectorAll('.cell').forEach(cell => cell.classList.remove('drag-over'));
    });

    unit.addEventListener('click', () => {
        selectedUnit = unit.dataset.type;
        unit.classList.add('selected');
        document.querySelectorAll('.unit').forEach(u => {
            if (u !== unit) u.classList.remove('selected');
        });
        console.log('Selected unit:', selectedUnit); // Debug
    });
});

document.addEventListener('dragover', (e) => {
    dragGhost.style.left = `${e.pageX - 16}px`;
    dragGhost.style.top = `${e.pageY - 16}px`;
});

battlefield.addEventListener('click', (e) => {
    const cell = e.target.closest('.cell');
    if (!cell) return;

    if (!cell.childElementCount && selectedUnit) {
        console.log('Placing tower on cell:', cell.dataset.index); // Debug
        placeTower({ target: cell, preventDefault: () => {} });
        document.querySelectorAll('.unit').forEach(u => u.classList.remove('selected'));
        selectedUnit = null;
    }
});

// Part 5: Tower Placement
function placeTower(e) {
    e.preventDefault();
    if (!gameActive || !selectedUnit || e.target.childElementCount > 0) return;
    const tower = towers[selectedUnit];
    if (supplies >= tower.cost) {
        supplies -= tower.cost;
        supplyCount.textContent = supplies;
        const towerDiv = document.createElement('div');
        towerDiv.classList.add('tower');
        const soldier = document.createElement('img');
        soldier.src = tower.sprite;
        towerDiv.appendChild(soldier);
        towerDiv.dataset.type = selectedUnit;
        towerDiv.dataset.damage = tower.damage;
        towerDiv.dataset.range = tower.range;
        towerDiv.dataset.fireRate = tower.fireRate;
        towerDiv.dataset.level = 1;
        towerDiv.dataset.health = 50;

        const upgradeBtn = document.createElement('button');
        upgradeBtn.classList.add('upgrade-btn');
        upgradeBtn.textContent = 'Upgrade';
        upgradeBtn.addEventListener('click', (event) => upgradeTower(event, towerDiv));
        towerDiv.appendChild(upgradeBtn);

        e.target.appendChild(towerDiv);
        startFiring(towerDiv, e.target.dataset.index);

        if (tower.ability === 'boost') {
            setInterval(() => activateBoost(towerDiv), 35000);
            activateBoost(towerDiv);
        }

        setInterval(() => {
            if (Math.random() < 0.3) showBattleCry(towerDiv);
        }, 10000);
    }
    e.target.classList.remove('drag-over');
}

// Part 6: Tower Upgrading and Abilities
function upgradeTower(event, towerDiv) {
    event.stopPropagation();
    const level = parseInt(towerDiv.dataset.level);
    if (level >= 3) return;

    const upgradeCost = level * 15;
    if (supplies >= upgradeCost) {
        supplies -= upgradeCost;
        supplyCount.textContent = supplies;

        // Update tower stats
        towerDiv.dataset.level = level + 1;
        towerDiv.dataset.damage = parseInt(towerDiv.dataset.damage) + 5;
        towerDiv.dataset.range = parseInt(towerDiv.dataset.range) + 1;
        towerDiv.dataset.health = parseInt(towerDiv.dataset.health) + 20;

        // Add chevron for visual upgrade indication
        const chevrons = towerDiv.querySelectorAll('.chevron').length;
        if (chevrons < level + 1) { // Add chevron to match new level
            const chevron = document.createElement('div');
            chevron.classList.add('chevron');
            towerDiv.appendChild(chevron);
        }

        // Disable upgrade button at max level
        if (level + 1 === 3) {
            const btn = towerDiv.querySelector('.upgrade-btn');
            btn.classList.add('disabled');
            btn.disabled = true;
        }

        // Restart firing with updated stats
        const cellIndex = towerDiv.parentElement.dataset.index;
        const existingInterval = parseInt(towerDiv.dataset.fireInterval);
        if (!isNaN(existingInterval)) {
            clearInterval(existingInterval);
        }
        const newInterval = startFiring(towerDiv, cellIndex);
        towerDiv.dataset.fireInterval = newInterval;
    }
}

function autoUpgradeTower(towerDiv) {
    const level = parseInt(towerDiv.dataset.level);
    if (level >= 3) return;

    // Update tower stats
    towerDiv.dataset.level = level + 1;
    towerDiv.dataset.damage = parseInt(towerDiv.dataset.damage) + 5;
    towerDiv.dataset.range = parseInt(towerDiv.dataset.range) + 1;
    towerDiv.dataset.health = parseInt(towerDiv.dataset.health) + 20;

    // Add chevron for visual upgrade indication
    const chevrons = towerDiv.querySelectorAll('.chevron').length;
    if (chevrons < level + 1) { // Add chevron to match new level
        const chevron = document.createElement('div');
        chevron.classList.add('chevron');
        towerDiv.appendChild(chevron);
    }

    // Disable upgrade button at max level
    if (level + 1 === 3) {
        const btn = towerDiv.querySelector('.upgrade-btn');
        btn.classList.add('disabled');
        btn.disabled = true;
    }

    // Restart firing with updated stats
    const cellIndex = towerDiv.parentElement.dataset.index;
    const existingInterval = parseInt(towerDiv.dataset.fireInterval);
    if (!isNaN(existingInterval)) {
        clearInterval(existingInterval);
    }
    const newInterval = startFiring(towerDiv, cellIndex);
    towerDiv.dataset.fireInterval = newInterval;
}

function activateBoost(towerDiv) {
    if (towerDiv.dataset.boostCooldown) return;

    towerDiv.classList.add('aura-active');
    const cellIndex = parseInt(towerDiv.parentElement.dataset.index);
    const row = Math.floor(cellIndex / 10);
    const col = cellIndex % 10;

    // Boost nearby towers within 1 cell radius (3x3 grid)
    for (let r = Math.max(0, row - 1); r <= Math.min(4, row + 1); r++) {
        for (let c = Math.max(0, col - 1); c <= Math.min(9, col + 1); c++) {
            const nearbyCell = document.querySelector(`.cell[data-index="${r * 10 + c}"]`);
            if (nearbyCell && nearbyCell.querySelector('.tower')) {
                const nearbyTower = nearbyCell.querySelector('.tower');
                const originalDamage = parseInt(nearbyTower.dataset.damage);
                nearbyTower.dataset.damage = originalDamage * 1.5; // 50% attack buff
                setTimeout(() => {
                    nearbyTower.dataset.damage = originalDamage; // Revert after 5s
                }, 5000);
            }
        }
    }

    // Boost duration and cooldown
    setTimeout(() => {
        towerDiv.classList.remove('aura-active');
        towerDiv.dataset.boostCooldown = 'true';
        setTimeout(() => delete towerDiv.dataset.boostCooldown, 30000); // 30s cooldown
    }, 5000); // 5s boost duration
}

function redeployTower(towerDiv) {
    towerDiv.classList.add('selected');
    selectedUnit = towerDiv.dataset.type;
    const cell = towerDiv.parentElement;

    // Clear firing interval if it exists
    const existingInterval = parseInt(towerDiv.dataset.fireInterval);
    if (!isNaN(existingInterval)) {
        clearInterval(existingInterval);
        delete towerDiv.dataset.fireInterval;
    }

    cell.innerHTML = ''; // Remove tower from current cell
    document.querySelectorAll('.cell').forEach(c => c.classList.add('drag-over')); // Highlight droppable cells
}

// Redeploy button listener
document.getElementById('redeploy-btn').addEventListener('click', () => {
    const selectedTower = document.querySelector('.tower.selected');
    if (selectedTower) {
        redeployTower(selectedTower);
    } else {
        alert('Select a soldier to redeploy by clicking it first!');
    }
});

// Battlefield click handler for tower selection and placement
battlefield.addEventListener('click', (e) => {
    const cell = e.target.closest('.cell');
    if (!cell) return;

    if (!cell.childElementCount && selectedUnit) {
        placeTower({ target: cell, preventDefault: () => {} });
        document.querySelectorAll('.unit').forEach(u => u.classList.remove('selected'));
        selectedUnit = null;
    } else if (cell.querySelector('.tower')) {
        const tower = cell.querySelector('.tower');
        tower.classList.toggle('selected');
        document.querySelectorAll('.tower').forEach(t => {
            if (t !== tower) t.classList.remove('selected');
        });
    }
});

// Part 7: Supply Generation and Drops
function generateSupplies() {
    setInterval(() => {
        if (gameActive) { // Only generate when game is active
            supplies += Math.floor(5 * (1 + waveCount * 0.1));
            supplyCount.textContent = supplies;
            if (Math.random() < 0.1) spawnSupplyDrop();
        }
    }, 5000);
}
generateSupplies();

// Part 8: Speed Controls
const speedButtons = { 'speed-1x': 1, 'speed-2x': 2 };
Object.keys(speedButtons).forEach(buttonId => {
    document.getElementById(buttonId).addEventListener('click', () => {
        gameSpeed = speedButtons[buttonId];
        document.querySelectorAll('.speed-btn').forEach(btn => btn.classList.remove('active'));
        document.getElementById(buttonId).classList.add('active');
    });
});

// Part 9: Enemy Spawning and Wave Management
startWaveBtn.addEventListener('click', startNextLevel);

function startNextLevel() {
    if (!gameActive) {
        gameActive = true; // Start game on first wave
    }
    waveCount++;
    waveNumber.textContent = waveCount;
    spawnWave(waveCount);
    startWaveBtn.style.display = 'none';
}

function spawnWave(level) {
    totalEnemiesInWave = Math.floor(5 + level * 2 + Math.pow(level - 1, 1.5));
    enemiesSpawned = 0;
    const healthMultiplier = 1 + level * 0.1;
    const halfWave = Math.floor(totalEnemiesInWave / 2);

    for (let i = 0; i < totalEnemiesInWave; i++) {
        setTimeout(() => {
            if (!gameActive) return; // Stop spawning if game is over

            let enemyType;
            // Spawn miniboss in last 5 enemies
            if (i >= totalEnemiesInWave - 5 && i === totalEnemiesInWave - 5) {
                enemyType = selectMiniboss();
                announceMiniboss(enemyType.name);
            } else {
                enemyType = selectEnemyType(level);
            }
            enemyType.health = Math.floor(enemyType.health * healthMultiplier);
            const baseSpeed = enemyType.speed;
            const speedMultiplier = Math.min(1 + (level - 1) * 0.02, 1.2);
            enemyType.speed = baseSpeed * speedMultiplier;
            const row = Math.floor(Math.random() * 5);
            const enemy = createEnemy(enemyType, row);

            // Banzai logic: after half wave, up to 3 times
            if (i >= halfWave && banzaiCount < maxBanzai && Math.random() < 0.1) {
                triggerBanzai(enemy);
            }

            battlefield.appendChild(enemy);
            moveEnemy(enemy, row);
            enemiesSpawned++;
            updateWaveProgress();
        }, i * 1000 / gameSpeed);
    }
}

function selectEnemyType(level) {
    const roll = Math.random();
    if (level > 5 && roll < 0.05 * (level / 10)) {
        return {
            type: 'commander',
            name: 'Enemy Commander',
            health: 100,
            speed: 0.4,
            sprite: 'https://i.imgur.com/4Z1YvwF.png',
            damage: 20,
            ability: 'splash'
        };
    }
    return { ...enemies[Math.floor(Math.random() * enemies.length)] };
}

function selectMiniboss() {
    const minibosses = [
        { type: 'miniboss', name: 'Lieutenant Tōichi', health: 150, speed: 0.5, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 25, ability: 'splash' },
        { type: 'miniboss', name: 'Lieutenant Ryuji', health: 140, speed: 0.6, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 20, ability: 'none' },
        { type: 'miniboss', name: 'Major Tadamichi Kuribayashi', health: 200, speed: 0.4, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 30, ability: 'splash' },
        { type: 'miniboss', name: 'Colonel Ryosaburo Tanaka', health: 180, speed: 0.5, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 25, ability: 'none' },
        { type: 'miniboss', name: 'Major Masa Orita', health: 160, speed: 0.55, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 22, ability: 'splash' },
        { type: 'miniboss', name: 'Colonel Chōsei Oyadomari', health: 190, speed: 0.45, sprite: 'https://i.imgur.com/4Z1YvwF.png', damage: 28, ability: 'none' }
    ];
    return minibosses[Math.floor(Math.random() * minibosses.length)];
}

function createEnemy(enemyType, row) {
    const enemy = document.createElement('div');
    enemy.classList.add('enemy');
    if (enemyType.type === 'miniboss' || enemyType.type === 'commander') enemy.classList.add('mini-boss');
    const img = document.createElement('img');
    img.src = enemyType.sprite;
    enemy.appendChild(img);
    const nameTag = document.createElement('div');
    nameTag.classList.add('enemy-name');
    nameTag.textContent = enemyType.name;
    enemy.appendChild(nameTag);
    const healthBar = document.createElement('div');
    healthBar.classList.add('health-bar');
    healthBar.style.width = '64px';
    enemy.appendChild(healthBar);
    enemy.dataset.health = enemyType.health;
    enemy.dataset.maxHealth = enemyType.health;
    enemy.dataset.speed = enemyType.speed;
    enemy.dataset.damage = enemyType.damage;
    enemy.dataset.ability = enemyType.ability;
    enemy.dataset.attackCooldown = 0;
    enemy.style.left = '640px';
    enemy.style.top = `${row * 64 + 3}px`;

    setInterval(() => {
        if (Math.random() < 0.3 && gameActive && enemy.parentElement) {
            showEnemyBattleCry(enemy);
        }
    }, 10000);

    return enemy;
}

function triggerBanzai(enemy) {
    if (banzaiCount >= maxBanzai) return;
    enemy.classList.add('banzai');
    enemy.dataset.speed = parseFloat(enemy.dataset.speed) * 2; // 2x speed
    enemy.dataset.health = parseFloat(enemy.dataset.health) / 2; // 2x easier to kill
    const banzaiText = document.createElement('div');
    banzaiText.classList.add('banzai-text');
    banzaiText.textContent = 'Banzai!';
    enemy.appendChild(banzaiText);
    showEnemyBattleCry(enemy, "Banzai!");
    banzaiCount++;

    setTimeout(() => {
        if (enemy.parentElement) { // Only revert if enemy still exists
            enemy.classList.remove('banzai');
            enemy.dataset.speed = parseFloat(enemy.dataset.speed) / 2; // Revert speed
            enemy.dataset.health = parseFloat(enemy.dataset.health) * 2; // Revert health
            banzaiText.remove();
        }
    }, 3000); // 3s duration

    const row = Math.floor((parseFloat(enemy.style.top) - 3) / 64);
    Array.from(battlefield.querySelectorAll('.enemy')).forEach(otherEnemy => {
        const otherRow = Math.floor((parseFloat(otherEnemy.style.top) - 3) / 64);
        if (otherEnemy !== enemy && otherRow === row && Math.random() < 0.5) {
            otherEnemy.classList.add('banzai');
            otherEnemy.dataset.speed = parseFloat(otherEnemy.dataset.speed) * 2;
            otherEnemy.dataset.health = parseFloat(otherEnemy.dataset.health) / 2;
            const otherText = document.createElement('div');
            otherText.classList.add('banzai-text');
            otherText.textContent = 'Banzai!';
            otherEnemy.appendChild(otherText);
            showEnemyBattleCry(otherEnemy, "Banzai!");
            setTimeout(() => {
                if (otherEnemy.parentElement) {
                    otherEnemy.classList.remove('banzai');
                    otherEnemy.dataset.speed = parseFloat(otherEnemy.dataset.speed) / 2;
                    otherEnemy.dataset.health = parseFloat(otherEnemy.dataset.health) * 2;
                    otherText.remove();
                }
            }, 3000);
        }
    });
}

function announceMiniboss(name) {
    let announcement = document.getElementById('announcement');
    if (!announcement) {
        announcement = document.createElement('div');
        announcement.id = 'announcement';
        battlefield.appendChild(announcement);
    }
    announcement.textContent = `${name} has arrived!`;
    announcement.style.display = 'block';
    setTimeout(() => {
        if (announcement) announcement.style.display = 'none';
    }, 3000);
}

// Part 10: Enemy Movement and Attack
function moveEnemy(enemy, row) {
    let pos = 640;
    const baseSpeed = parseFloat(enemy.dataset.speed);
    const moveInterval = setInterval(() => {
        if (!gameActive || !enemy.parentElement) {
            clearInterval(moveInterval);
            return;
        }
        const fortified = Array.from(document.querySelectorAll('.fortified')).some(cell => {
            const cellX = parseInt(cell.dataset.index % 10) * 64;
            return Math.abs(cellX - pos) < 32 && Math.floor(cell.dataset.index / 10) === row;
        });
        const speed = fortified ? baseSpeed * 0.5 : baseSpeed;
        pos -= speed;
        enemy.style.left = `${pos}px`;
        lastActivityTime = Date.now(); // Update activity time
        const tower = checkEnemyAttack(enemy, row, pos);
        if (tower) {
            attackTower(enemy, tower);
        } else if (pos <= 0) {
            clearInterval(moveInterval);
            enemy.remove();
            endGame();
            updateWaveProgress();
        }
    }, 50 / gameSpeed);
}

function checkEnemyAttack(enemy, row, pos) {
    const col = Math.floor(pos / 64);
    const cellIndex = row * 10 + col;
    const cell = document.querySelector(`.cell[data-index="${cellIndex}"]`);
    return cell && cell.querySelector('.tower');
}

function attackTower(enemy, tower) {
    const isRanged = enemy.dataset.ability === 'splash';
    const damage = parseInt(enemy.dataset.damage);
    let towerHealth = parseInt(tower.dataset.health);

    if (isRanged) {
        let cooldown = parseInt(enemy.dataset.attackCooldown) || 0;
        if (cooldown <= 0) {
            towerHealth -= damage;
            tower.dataset.health = towerHealth;
            tower.style.animation = 'flash 0.3s';
            if (enemy.dataset.ability === 'splash') splashDamage(tower, damage);
            enemy.dataset.attackCooldown = 2000 / gameSpeed;
            if (Math.random() < 0.2) showHitReaction(tower);
        } else {
            enemy.dataset.attackCooldown = cooldown - 50;
        }
    } else {
        towerHealth -= damage;
        tower.dataset.health = towerHealth;
        tower.style.animation = 'flash 0.3s';
        if (Math.random() < 0.2) showHitReaction(tower);
    }

    if (towerHealth <= 0) {
        tower.parentElement.innerHTML = '';
    }
}

function splashDamage(tower, damage) {
    const cellIndex = parseInt(tower.parentElement.dataset.index);
    const row = Math.floor(cellIndex / 10);
    const col = cellIndex % 10;
    for (let r = Math.max(0, row - 1); r <= Math.min(4, row + 1); r++) {
        for (let c = Math.max(0, col - 1); c <= Math.min(9, col + 1); c++) {
            const nearbyCell = document.querySelector(`.cell[data-index="${r * 10 + c}"]`);
            if (nearbyCell && nearbyCell.querySelector('.tower')) {
                const nearbyTower = nearbyCell.querySelector('.tower');
                nearbyTower.dataset.health = parseInt(nearbyTower.dataset.health) - Math.floor(damage / 2);
                nearbyTower.style.animation = 'flash 0.3s';
                if (parseInt(nearbyTower.dataset.health) <= 0) nearbyTower.parentElement.innerHTML = '';
            }
        }
    }
}

function startFiring(tower, cellIndex) {
    const row = Math.floor(cellIndex / 10);
    const col = cellIndex % 10;
    const fireRate = parseInt(tower.dataset.fireRate);

    const fireInterval = setInterval(() => {
        if (!gameActive || !tower.parentElement) {
            clearInterval(fireInterval);
            return;
        }

        const enemiesInRange = Array.from(battlefield.querySelectorAll('.enemy')).filter(enemy => {
            const enemyX = parseFloat(enemy.style.left);
            const enemyRow = Math.floor((parseFloat(enemy.style.top) - 3) / 64);
            const towerX = col * 64;
            const range = parseInt(tower.dataset.range) * 64;
            return enemyRow === row && enemyX > towerX && enemyX <= towerX + range;
        });

        if (enemiesInRange.length > 0) {
            lastActivityTime = Date.now(); // Update activity time
            const target = enemiesInRange.reduce((closest, enemy) => {
                const enemyX = parseFloat(enemy.style.left);
                const closestX = closest ? parseFloat(closest.style.left) : Infinity;
                return enemyX < closestX ? enemy : closest;
            }, null);

            if (target) {
                fireBullet(tower, target, row);

                if (tower.dataset.type === 'rajputs' && Math.abs(parseFloat(target.style.left) - (col * 64)) <= 64) {
                    tower.classList.add('special-attack');
                    setTimeout(() => tower.classList.remove('special-attack'), 700);
                    target.dataset.health = parseInt(target.dataset.health) - 10;
                    target.style.animation = 'flash 0.3s';
                    if (Math.random() < 0.2) showHitReaction(target);
                    if (parseInt(target.dataset.health) <= 0) {
                        target.remove();
                        enemiesDefeated++;
                        score += 10 + waveCount * 5;
                        if (Math.random() < 0.3) showCelebration(tower);
                        updateKills(tower); // Track kills for promotion
                        updateWaveProgress();
                    }
                }
            }
        }
    }, fireRate / gameSpeed);

    return fireInterval;
}

// Part 11: Tower Firing Logic
function startFiring(tower, cellIndex) {
    const row = Math.floor(cellIndex / 10);
    const col = cellIndex % 10;
    const fireRate = parseInt(tower.dataset.fireRate);

    const fireInterval = setInterval(() => {
        if (!gameActive || !tower.parentElement) {
            clearInterval(fireInterval);
            return;
        }

        const enemiesInRange = Array.from(battlefield.querySelectorAll('.enemy')).filter(enemy => {
            const enemyX = parseFloat(enemy.style.left);
            const enemyRow = Math.floor((parseFloat(enemy.style.top) - 3) / 64);
            const towerX = col * 64;
            const range = parseInt(tower.dataset.range) * 64;
            return enemyRow === row && enemyX > towerX && enemyX <= towerX + range;
        });

        if (enemiesInRange.length > 0) {
            lastActivityTime = Date.now();
            const target = enemiesInRange.reduce((closest, enemy) => {
                const enemyX = parseFloat(enemy.style.left);
                const closestX = closest ? parseFloat(closest.style.left) : Infinity;
                return enemyX < closestX ? enemy : closest;
            }, null);

            if (target) {
                fireBullet(tower, target, row);

                if (tower.dataset.type === 'rajputs' && Math.abs(parseFloat(target.style.left) - (col * 64)) <= 64) {
                    tower.classList.add('special-attack');
                    setTimeout(() => tower.classList.remove('special-attack'), 700);
                    target.dataset.health = parseInt(target.dataset.health) - 10;
                    target.style.animation = 'flash 0.3s';
                    if (Math.random() < 0.2) showHitReaction(target);
                    if (parseInt(target.dataset.health) <= 0) {
                        target.remove();
                        enemiesDefeated++;
                        score += 10 + waveCount * 5;
                        if (Math.random() < 0.3) showCelebration(tower);
                        updateKills(tower); // Track kills for promotion
                        updateWaveProgress();
                    }
                }
            }
        }
    }, fireRate / gameSpeed);

    return fireInterval;
}

// Part 12: Bullet Firing and Damage
function fireBullet(tower, target, row) {
    const bullet = document.createElement('div');
    bullet.classList.add('bullet');
    const towerX = (parseInt(tower.parentElement.dataset.index) % 10) * 64 + 32;
    bullet.style.left = `${towerX}px`;
    bullet.style.top = `${row * 64 + 32}px`;
    battlefield.appendChild(bullet);

    const bangText = document.createElement('div');
    bangText.classList.add('fire-text');
    bangText.textContent = 'Bang';
    tower.appendChild(bangText);
    setTimeout(() => bangText.remove(), 400);

    const shootSound = document.getElementById('shoot-sound');
    shootSound.currentTime = 0;
    shootSound.play();

    let bulletX = towerX;
    const moveBullet = setInterval(() => {
        if (!target.parentElement || !bullet.parentElement) {
            clearInterval(moveBullet);
            bullet.remove();
            return;
        }

        bulletX += 5 * gameSpeed;
        bullet.style.left = `${bulletX}px`;
        const targetX = parseFloat(target.style.left);

        if (bulletX >= targetX) {
            clearInterval(moveBullet);
            bullet.remove();

            let health = parseInt(target.dataset.health) - parseInt(tower.dataset.damage);
            target.dataset.health = health;
            const maxHealth = parseInt(target.dataset.maxHealth);
            target.querySelector('.health-bar').style.width = `${(health / maxHealth) * 64}px`;
            target.style.animation = 'flash 0.3s';
            if (Math.random() < 0.2) showHitReaction(target);

            if (health <= 0) {
                lastActivityTime = Date.now();
                const explosion = document.createElement('div');
                explosion.classList.add('explosion');
                explosion.style.left = `${targetX}px`;
                explosion.style.top = target.style.top;
                battlefield.appendChild(explosion);
                setTimeout(() => explosion.remove(), 300);
                target.remove();
                enemiesDefeated++;
                score += 10 + waveCount * 5;
                if (Math.random() < 0.3) showCelebration(tower);
                updateKills(tower); // Track kills for promotion
                updateWaveProgress();
            }
        }
    }, 20 / gameSpeed);
}

// Part 12.1: Helper Functions (Updated)
function showEnemyBattleCry(enemy, forcedText = null) {
    const cries = [
        "Banzai!", "Kill you!", "For the Emperor!", 
        "Charge!", "Death to the enemy!", "Tenno Heika!", 
        "Forward!", "Victory or death!"
    ];
    const cry = document.createElement('div');
    cry.classList.add('battle-cry');
    cry.textContent = forcedText || cries[Math.floor(Math.random() * cries.length)];
    cry.style.left = '50%';
    cry.style.top = '0';
    cry.style.transform = 'translateX(-50%)';
    enemy.appendChild(cry);
    setTimeout(() => cry.remove(), 2000);
}

// Part 13: Wave Progress and New Features
function updateWaveProgress() {
    const enemiesRemaining = document.querySelectorAll('.enemy').length;
    enemiesRemainingDisplay.textContent = `${enemiesRemaining}/${totalEnemiesInWave}`;
    const progress = (enemiesSpawned - enemiesRemaining) / totalEnemiesInWave * 100;
    progressBar.style.width = `${progress}%`;
    if (enemiesRemaining === 0 && enemiesSpawned >= totalEnemiesInWave) { // >= to account for miniboss
        checkWaveCompletion();
    }
}

function updateKills(tower) {
    const towerId = tower.dataset.fireInterval; // Unique ID based on interval
    let kills = towerKills.get(towerId) || 0;
    kills += 1;
    towerKills.set(towerId, kills);
    if (kills >= 5) {
        autoUpgradeTower(tower);
        towerKills.set(towerId, 0); // Reset kills after promotion
    }
}

function checkActivity() {
    setInterval(() => {
        if (gameActive && Date.now() - lastActivityTime > 30000) { // 30s inactivity
            const enemies = document.querySelectorAll('.enemy').length;
            const towersFiring = document.querySelectorAll('.tower').length > 0;
            if (enemies === 0 && towersFiring) {
                let notification = document.getElementById('bug-notification');
                if (!notification) {
                    notification = document.createElement('div');
                    notification.id = 'bug-notification';
                    battlefield.appendChild(notification);
                }
                notification.textContent = "Bug: Let's go to next level";
                notification.style.display = 'block';
                setTimeout(() => {
                    notification.style.display = 'none';
                    checkWaveCompletion(); // Force next level
                }, 3000);
            }
        }
    }, 1000); // Check every second
}
checkActivity();

function checkWaveCompletion() {
    supplies += Math.floor(20 + waveCount * 5);
    supplyCount.textContent = supplies;
    score += waveCount * 50 + enemiesDefeated * 5;
    gameOverDiv.innerHTML = `
        Wave ${waveCount} Cleared!<br>
        Score: ${score}<br>
        Enemies Defeated: ${enemiesDefeated}<br>
        <button id="next-level">Next Wave (${waveCount + 1})</button>
    `;
    gameOverDiv.style.display = 'block';
    document.getElementById('next-level').addEventListener('click', () => {
        gameOverDiv.style.display = 'none';
        startNextLevel();
    });
}

function endGame() {
    gameActive = false;
    gameOverDiv.innerHTML = `
        Game Over!<br>
        Reached Wave: ${waveCount}<br>
        Final Score: ${score}<br>
        Enemies Defeated: ${enemiesDefeated}<br>
        <button id="restart">Restart Challenge</button>
        <p style="font-size: 16px; margin-top: 10px;">Can you beat Wave ${waveCount + 1} next time?</p>
    `;
    gameOverDiv.style.display = 'block';
    document.getElementById('restart').addEventListener('click', restartGame);
}

function restartGame() {
    gameActive = true;
    supplies = 50;
    waveCount = 0;
    score = 0;
    enemiesDefeated = 0;
    totalEnemiesInWave = 0;
    enemiesSpawned = 0;
    gameSpeed = 1;
    supplyCount.textContent = supplies;
    waveNumber.textContent = waveCount;
    enemiesRemainingDisplay.textContent = '0/0';
    gameOverDiv.style.display = 'none';
    startWaveBtn.style.display = 'block';
    document.querySelectorAll('.speed-btn').forEach(btn => btn.classList.remove('active'));
    document.getElementById('speed-1x').classList.add('active');
    battlefield.innerHTML = '';
    setupBattlefield();
    alert("New challenge begins! How many waves can you survive?");
}